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
      path = [pkgs.git pkgs.openssh colmenaPkg pkgs.nix pkgs.curl pkgs.jq pkgs.sudo];
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

          # 1. Run Fleet Deployment (Allow partial failure)
          set +e
          colmena apply --color always --parallel 1 --keep-result
          FLEET_EXIT=$?
          set -e

          # 2. Self-update dev-nixos
          echo -e "\n''${B}🏠 Self-updating dev-nixos...''${NC}"
          if sudo colmena apply-local --color always --node dev-nixos; then
             LOCAL_EXIT=0
          else
             LOCAL_EXIT=1
          fi

          # 3. Decision & Notification
          if [ $FLEET_EXIT -eq 0 ] && [ $LOCAL_EXIT -eq 0 ]; then
             echo -e "\n''${G}✅ FULL SUCCESS: All systems operational''${NC}"
             TITLE="🚀 Deployment Success"
             MSG="All nodes updated to $(git rev-parse --short HEAD)"
             PRIORITY=5
          elif [ $LOCAL_EXIT -eq 0 ]; then
             echo -e "\n''${O}⚠️  PARTIAL SUCCESS: Some fleet nodes failed''${NC}"
             TITLE="⚠️ Partial Deployment"
             MSG="dev-nixos updated, but some fleet nodes failed. Check logs."
             PRIORITY=8
          else
             echo -e "\n''${R}❌ CRITICAL: dev-nixos update failed''${NC}"
             TITLE="❌ Deployment Critical Failure"
             MSG="Local monitoring node (dev-nixos) failed to update."
             PRIORITY=9
             exit 1 # Fail the service
          fi

          if [ -f /var/lib/internal-gitops/gotify_token ]; then
            TOKEN=$(cat /var/lib/internal-gitops/gotify_token)
            curl -s -S -X POST "http://gotify:8080/message?token=$TOKEN" \
              -F "title=$TITLE" \
              -F "message=$MSG" \
              -F "priority=$PRIORITY" > /dev/null
          fi

        else
          echo -e "''${G}😴 No changes found. System is up to date.''${NC}"
        fi
      '';
      serviceConfig = {
        User = "nixos";
        Type = "oneshot";
        StateDirectory = "internal-gitops";
        Environment = "PATH=${lib.makeBinPath [pkgs.git pkgs.openssh colmenaPkg pkgs.nix pkgs.curl pkgs.jq]}";
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
