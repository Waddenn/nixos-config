{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  options.deployerNode.enable = lib.mkEnableOption "Enable internal GitOps controller";

  config = lib.mkIf config.deployerNode.enable {
    environment.systemPackages = [
      pkgs.git
      inputs.colmena.packages.${pkgs.system}.colmena or pkgs.colmena
    ];

    systemd.services.internal-gitops = let
      colmenaPkg = inputs.colmena.packages.${pkgs.system}.colmena;
    in {
      description = "Internal GitOps: Pull and Deploy";
      # Prevent the service from restarting during activation (would kill the running script)
      stopIfChanged = false;
      path = [pkgs.git pkgs.openssh colmenaPkg pkgs.nix pkgs.curl pkgs.jq pkgs.gnugrep pkgs.gawk "/run/wrappers"];
      script = ''
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

        echo -e "\n''${B}╔════════════════════════════════════════════════════════╗''${NC}"
        echo -e "''${B}║           🚀 INTERNAL GITOPS: AUTO-DEPLOYER            ║''${NC}"
        echo -e "''${B}╚════════════════════════════════════════════════════════╝''${NC}\n"

        echo -e "''${Y}🔍 Checking for updates...''${NC}"
        git fetch origin main > /dev/null 2>&1

        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse origin/main)

        if [ "$LOCAL" != "$REMOTE" ]; then
          echo -e "''${G}✨ New changes detected!''${NC} syncing..."
          git merge origin/main > /dev/null 2>&1

          echo -e "''${B}🏗️  Starting Deployment...''${NC}"
          echo -e "''${B}----------------------------------------------------------''${NC}"

          # Create a temporary log file
          LOGFILE=$(mktemp)

          # 1. Run Fleet Deployment (Allow partial failure)
          set +e
          # Pipe stdout/stderr to tee to show in journal AND save to file
          colmena apply --color always --parallel 2 --keep-result --on @remote 2>&1 | tee "$LOGFILE"
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

          # 2. Self-update dev-nixos
          echo -e "\n''${B}🏠 Self-updating dev-nixos...''${NC}"
          if sudo colmena apply-local --color always --node dev-nixos; then
             LOCAL_EXIT=0
             if [ -z "$SUCCEEDED_LIST" ]; then SUCCEEDED_LIST="dev-nixos"; else SUCCEEDED_LIST="$SUCCEEDED_LIST, dev-nixos"; fi
          else
             LOCAL_EXIT=1
             if [ -z "$FAILED_LIST" ]; then FAILED_LIST="dev-nixos"; else FAILED_LIST="$FAILED_LIST, dev-nixos"; fi
          fi

          # 3. Decision & Notification
          COMMIT_HASH=$(git rev-parse --short HEAD)
          REPORT_BODY="Commit: $COMMIT_HASH"
          
          if [ -n "$SUCCEEDED_LIST" ]; then
            REPORT_BODY="$REPORT_BODY\n\n✅ **Updated:** $SUCCEEDED_LIST"
          fi
          
          if [ -n "$FAILED_LIST" ]; then
             REPORT_BODY="$REPORT_BODY\n\n❌ **Failed:** $FAILED_LIST"
          fi

          if [ $FLEET_EXIT -eq 0 ] && [ $LOCAL_EXIT -eq 0 ]; then
             echo -e "\n''${G}✅ FULL SUCCESS: All systems operational''${NC}"
             TITLE="🚀 Deployment Success"
             PRIORITY=5
          elif [ $LOCAL_EXIT -eq 0 ]; then
             echo -e "\n''${O}⚠️  PARTIAL SUCCESS: Some fleet nodes failed''${NC}"
             TITLE="⚠️ Partial Deployment"
             PRIORITY=8
          else
             echo -e "\n''${R}❌ CRITICAL: dev-nixos update failed''${NC}"
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
          echo -e "''${G}😴 No changes found. System is up to date.''${NC}"
        fi
      '';
      serviceConfig = {
        User = "nixos";
        Type = "oneshot";
        StateDirectory = "internal-gitops";
      };
    };

    systemd.timers.internal-gitops = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "10m"; # Check every 10 minutes
        RandomizedDelaySec = "1m";
      };
    };
  };
}
