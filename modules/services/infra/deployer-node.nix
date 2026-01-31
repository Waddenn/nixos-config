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
      path = [pkgs.git pkgs.openssh colmenaPkg pkgs.nix pkgs.curl pkgs.jq];
      script = ''
        set -e
        # Colors & Emojis
        G='\033[0;32m'
        B='\033[0;34m'
        Y='\033[1;33m'
        R='\033[0;31m'
        NC='\033[0m'

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

          echo -e "''${B}🏗️  Starting Fleet Deployment...''${NC}"
          echo -e "''${B}----------------------------------------------------------''${NC}"

          # Run deployment
          if colmena apply --color always --build-on-target --parallel 1 --keep-result; then
             echo -e "\n''${G}✅ DEPLOYMENT SUCCESSFUL''${NC}"
             if [ -f /var/lib/internal-gitops/gotify_token ]; then
               TOKEN=$(cat /var/lib/internal-gitops/gotify_token)
               curl -s -S -X POST "http://gotify:8080/message?token=$TOKEN" \
                 -F "title=🚀 Deployment Success" \
                 -F "message=Fleet successfully updated to $(git rev-parse --short HEAD)" \
                 -F "priority=5" > /dev/null
             fi
          else
             echo -e "\n''${R}❌ DEPLOYMENT FAILED''${NC}"
             if [ -f /var/lib/internal-gitops/gotify_token ]; then
               TOKEN=$(cat /var/lib/internal-gitops/gotify_token)
               curl -s -S -X POST "http://gotify:8080/message?token=$TOKEN" \
                 -F "title=⚠️ Deployment Failed" \
                 -F "message=Error during rollout to $(git rev-parse --short HEAD). Check journalctl on dev-nixos." \
                 -F "priority=8" > /dev/null
             fi
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
