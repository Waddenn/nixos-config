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
      path = [pkgs.git pkgs.openssh colmenaPkg pkgs.nix];
      script = ''
        set -e
        # Navigate to repo
        cd /home/nixos/nixos-config

        echo "Using Colmena version:"
        colmena --version

        # Update code
        git fetch origin main
        
        # Check if we are behind
        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse origin/main)

        if [ "$LOCAL" != "$REMOTE" ]; then
          echo "Changes detected. Pulling..."
          git merge origin/main
          
          echo "Deploying with Colmena..."
          # We use the colmena binary specifically provided in the service path
          colmena apply --build-on-target --parallel 2 --keep-result
        else
          echo "No changes."
        fi
      '';
      serviceConfig = {
        User = "nixos"; # Run as user who has the SSH keys
        Type = "oneshot";
        # Ensure we don't pick up the system colmena (0.5-pre)
        Environment = "PATH=${lib.makeBinPath [ pkgs.git pkgs.openssh colmenaPkg pkgs.nix ]}";
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
