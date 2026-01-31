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
  
  echo -e "${B}🏗️  Starting Deployment...${NC}"
  echo -e "${B}----------------------------------------------------------${NC}"

  # Create a temporary log file
  LOGFILE=$(mktemp)

  # 2. Run Fleet Deployment (Allow partial failure)
  set +e
  # Pipe stdout/stderr to tee to show in journal AND save to file
  colmena apply --color always --parallel 3 --keep-result --on @remote 2>&1 | tee "$LOGFILE"
  FLEET_EXIT=$?
  set -e

  # Parse logs for status
  # Remove color codes for reliable grep
  CLEAN_LOG=$(sed 's/\x1b\[[0-9;]*m//g' "$LOGFILE")
  
  # Extract successes (host | Activation successful)
  SUCCEEDED_LIST=$(echo "$CLEAN_LOG" | grep "| Activation successful" | awk -F '|' '{print $1}' | sort | tr '\n' ', ' | sed 's/, $//')
  
  # Extract failures (heuristic: [ERROR] Failed to push system closure to <host>)
  FAILED_LIST=$(echo "$CLEAN_LOG" | grep "Failed to push system closure to" | awk '{print $NF}' | sort | uniq | tr '\n' ', ' | sed 's/, $//')
  
  # Fallback for failures if specific pattern not found but FLEET_EXIT != 0
  if [ $FLEET_EXIT -ne 0 ] && [ -z "$FAILED_LIST" ]; then
     FAILED_LIST="Unknown/General Failure (See logs)"
  fi

  rm -f "$LOGFILE"

  # 3. Self-update dev-nixos
  echo -e "\n${B}🏠 Self-updating dev-nixos...${NC}"
  if sudo colmena apply-local --color always --node dev-nixos; then
     LOCAL_EXIT=0
     if [ -z "$SUCCEEDED_LIST" ]; then SUCCEEDED_LIST="dev-nixos"; else SUCCEEDED_LIST="$SUCCEEDED_LIST, dev-nixos"; fi
  else
     LOCAL_EXIT=1
     if [ -z "$FAILED_LIST" ]; then FAILED_LIST="dev-nixos"; else FAILED_LIST="$FAILED_LIST, dev-nixos"; fi
  fi

  # 4. Decision & Notification
  COMMIT_HASH=$(git rev-parse --short HEAD)
  REPORT_BODY="Commit: $COMMIT_HASH"
  
  if [ -n "$SUCCEEDED_LIST" ]; then
    REPORT_BODY="$REPORT_BODY\n\n✅ **Updated:** $SUCCEEDED_LIST"
  fi
  
  if [ -n "$FAILED_LIST" ]; then
     REPORT_BODY="$REPORT_BODY\n\n❌ **Failed:** $FAILED_LIST"
  fi

  if [ $FLEET_EXIT -eq 0 ] && [ $LOCAL_EXIT -eq 0 ]; then
     echo -e "\n${G}✅ FULL SUCCESS: All systems operational${NC}"
     TITLE="🚀 Deployment Success"
     PRIORITY=5
  elif [ $LOCAL_EXIT -eq 0 ]; then
     echo -e "\n${O}⚠️  PARTIAL SUCCESS: Some fleet nodes failed${NC}"
     TITLE="⚠️ Partial Deployment"
     PRIORITY=8
  else
     echo -e "\n${R}❌ CRITICAL: dev-nixos update failed${NC}"
     TITLE="❌ Deployment Critical Failure"
     PRIORITY=9
     # Even if critical, we try to send notification
  fi
  
  MSG="$REPORT_BODY"
  echo -e "$MSG"

  if [ -f /var/lib/internal-gitops/gotify_token ]; then
    TOKEN=$(cat /var/lib/internal-gitops/gotify_token)
    curl -s -S -X POST "http://gotify:8080/message?token=$TOKEN" \
      -F "title=$TITLE" \
      -F "message=$MSG" \
      -F "priority=$PRIORITY" \
      -F "extras[client::display][contentType]=text/markdown" > /dev/null
  fi

  # If critical local failure, exit with error to fail the systemd unit
  if [ $LOCAL_EXIT -ne 0 ]; then
     exit 1
  fi

else
  echo -e "${G}😴 No changes found. System is up to date.${NC}"
fi
