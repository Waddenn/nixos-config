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

    systemd.services.internal-gitops = {
      description = "Internal GitOps: Pull and Deploy";
      path = [pkgs.git pkgs.openssh inputs.colmena.packages.${pkgs.system}.colmena or pkgs.colmena pkgs.nix];
      script = ''
        set -e
        # Navigate to repo
        cd /home/nixos/nixos-config

        # Update code
        git fetch origin main
        
        # Check if we are behind
        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse origin/main)

        if [ "$LOCAL" != "$REMOTE" ]; then
          echo "Changes detected. Pulling..."
          git merge origin/main
          
          echo "Deploying with Colmena..."
          # Deploy to all *except* self first (to avoid cutting branch) or just all in parallel?
          # colmena apply handles self-update usually fine but let's be careful.
          colmena apply --build-on-target
        else
          echo "No changes."
        fi
      '';
      serviceConfig = {
        User = "nixos"; # Run as user who has the SSH keys
        Type = "oneshot";
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
