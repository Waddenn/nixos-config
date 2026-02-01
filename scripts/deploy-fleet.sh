#!/usr/bin/env bash
set -e

# Colors & Emojis
G='\033[0;32m'
B='\033[0;34m'
Y='\033[1;33m'
R='\033[0;31m'
NC='\033[0m'
O='\033[0;33m'

# Navigation
cd /home/nixos/nixos-config

echo -e "\n${B}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${B}║           🚀 INTERNAL GITOPS: AUTO-DEPLOYER            ║${NC}"
echo -e "${B}╚════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${Y}🔍 Checking for updates...${NC}"
git fetch origin main > /dev/null 2>&1

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" != "$REMOTE" ]; then
  echo -e "${G}✨ New changes detected!${NC}"
  
  # 0. Check CI Status
  # We use gh api to check the status of the latest commit on main
  # This requires GH_TOKEN to be set in the environment of the service
  if command -v gh >/dev/null 2>&1 && [ -n "$GH_TOKEN" ]; then
       echo -e "${Y}📡 Verifying CI Status...${NC}"
       CI_STATUS=$(gh api repos/:owner/:repo/commits/$REMOTE/check-runs --jq '.check_runs[] | select(.name == "nix-build") | .conclusion')
       
       # If we can't determine status (e.g. no checks), we proceed with caution or fail?
       # For now, let's assume if 'failure' is present, we abort.
       if echo "$CI_STATUS" | grep -q "failure"; then
            echo -e "${R}🛑 CI Check Failed for $REMOTE. Aborting deployment.${NC}"
            exit 0
       fi
       echo -e "${G}✅ CI Status Green.${NC}"
  else 
       echo -e "${O}⚠️  Skipping CI Check (gh missing or no token).${NC}"
  fi

  # 1. Hard Sync (GitOps Source of Truth)
  echo -e "${B}🔄 Syncing to origin/main (Reset --hard)...${NC}"
  git reset --hard origin/main
  
  START_TIME=$(date +%s)
  echo -e "${B}🏗️  Starting Deployment...${NC}"
  echo -e "${B}----------------------------------------------------------${NC}"

  # Create a temporary log file
  LOGFILE=$(mktemp)

  # 2. Run Fleet Deployment (Allow partial failure)
  set +e
  # Pipe stdout/stderr to tee to show in journal AND save to file
  colmena apply --color always --parallel 3 --keep-result --on @remote 2>&1 | tee "$LOGFILE"
  FLEET_EXIT=${PIPESTATUS[0]}
  set -e

  # Parse logs for status
  CLEAN_LOG=$(sed 's/\x1b\[[0-9;]*m//g' "$LOGFILE" || true)
  
  # Extract successes (host | Activation successful)
  SUCCEEDED_LIST=$(echo "$CLEAN_LOG" | grep "| Activation successful" | awk -F '|' '{gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}' | sort | uniq | tr '\n' ',' | sed 's/,$//; s/,/, /g' || true)
  
  # Extract failures 
  # 1. Pushing failures
  PUSH_FAILURES=$(echo "$CLEAN_LOG" | grep "Failed to push system closure to" | awk '{gsub(/^[ \t]+|[ \t]+$/, "", $NF); print $NF}' || true)
  # 2. Activation failures (catch nodes that failed after successful push)
  ACT_FAILURES=$(echo "$CLEAN_LOG" | grep "Activation failed" -B 1 | grep " | " | awk -F '|' '{gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}' || true)
  
  FAILED_LIST=$(echo -e "$PUSH_FAILURES\n$ACT_FAILURES" | grep -v "^$" | sort | uniq | tr '\n' ',' | sed 's/,$//; s/,/, /g' || true)
  
  # Fallback for failures if specific patterns not found but FLEET_EXIT != 0
  if [ $FLEET_EXIT -ne 0 ] && [ -z "$FAILED_LIST" ]; then
     FAILED_LIST="Unknown/General Failure (Check logs)"
  fi

  rm -f "$LOGFILE"

  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))
  DURATION_STR="$(($DURATION / 60))min $(($DURATION % 60))s"

  # 4. Success/Failure Notification
  COMMIT_HASH=$(git rev-parse --short HEAD)
  COMMIT_MSG=$(git log -1 --format=%s)
  
  REPORT_BODY="**Commit:** \`$COMMIT_HASH\` - $COMMIT_MSG
**Duration:** $DURATION_STR"
  
  if [ -n "$SUCCEEDED_LIST" ]; then
    REPORT_BODY="$REPORT_BODY

✅ **Updated:** $SUCCEEDED_LIST"
  fi
  
  if [ -n "$FAILED_LIST" ]; then
     REPORT_BODY="$REPORT_BODY

❌ **Failed:** $FAILED_LIST"
  fi

  if [ $FLEET_EXIT -eq 0 ]; then
     echo -e "\n${G}✅ FLEET SUCCESS: Nodes updated.${NC}"
     TITLE="🚀 Fleet Deployment Success"
     COLOR=3066993 # Green
  else
     echo -e "\n${O}⚠️  FLEET PARTIAL: Some nodes failed.${NC}"
     TITLE="⚠️ Fleet Partial Deployment"
     COLOR=15105570 # Orange
  fi
  
  # Send Fleet Notification
  echo -e "\n${B}📡 Debug: DISCORD_WEBHOOK exists? $([ -n "$DISCORD_WEBHOOK" ] && echo "YES" || echo "NO")${NC}"
  if [ -n "$DISCORD_WEBHOOK" ]; then
    echo -e "${B}📡 Sending Discord notification...${NC}"
    if [[ $DISCORD_WEBHOOK == discord://* ]]; then
        ID=$(echo "$DISCORD_WEBHOOK" | sed -E 's/discord:\/\/.*@(.*)/\1/' || true)
        TOKEN=$(echo "$DISCORD_WEBHOOK" | sed -E 's/discord:\/\/(.*)@.*/\1/' || true)
        WEBHOOK_URL="https://discord.com/api/webhooks/$ID/$TOKEN"
    else
        WEBHOOK_URL="$DISCORD_WEBHOOK"
    fi

    PAYLOAD=$(jq -n \
      --arg title "$TITLE" \
      --arg desc "$REPORT_BODY" \
      --arg color "$COLOR" \
      '{
        embeds: [{
          title: $title,
          description: $desc,
          color: ($color | tonumber),
          timestamp: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
        }]
      }')

    curl -s -X POST -H "Content-Type: application/json" -d "$PAYLOAD" "$WEBHOOK_URL" > /dev/null || echo -e "${R}❌ Failed to send notification${NC}"
  else
    echo -e "${O}⚠️  DISCORD_WEBHOOK not set, skipping notification.${NC}"
  fi

  # 5. Self-update dev-nixos (Fully detached)
  echo -e "\n${B}🏠 Triggering self-update for dev-nixos...${NC}"
  # We use COLMENA_BIN to ensure the command is found in the detached process.
  # We remove --wait to truly detach it and add --working-directory for flake discovery.
  sudo systemd-run --unit=dev-nixos-self-update --description="GitOps Self-Update" \
       --working-directory=/home/nixos/nixos-config \
       --property="Type=oneshot" --property="RemainAfterExit=no" \
       ${COLMENA_BIN:-colmena} apply-local --color always --node dev-nixos

else
  echo -e "${G}😴 No changes found. System is up to date.${NC}"
fi
