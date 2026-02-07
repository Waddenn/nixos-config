{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  options.my-services.infra.deployer-node.enable = lib.mkEnableOption "Enable internal GitOps controller";

  config = lib.mkIf config.my-services.infra.deployer-node.enable {
    environment.shellAliases = {
      gitops-force = "sudo touch /var/lib/internal-gitops/force && sudo systemctl start internal-gitops.service";
    };
    programs.fish.shellAliases = {
      gitops-force = "sudo touch /var/lib/internal-gitops/force; and sudo systemctl start internal-gitops.service";
    };

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "gitops-force" ''
        set -euo pipefail
        sudo touch /var/lib/internal-gitops/force
        sudo systemctl start internal-gitops.service
      '')
      pkgs.git
      pkgs.cachix
      inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena or pkgs.colmena
    ];

    sops.secrets.gh-token = {
      sopsFile = ../../../secrets/secrets.yaml;
      owner = "nixos";
    };
    sops.secrets.discord-webhook = {
      sopsFile = ../../../secrets/secrets.yaml;
      owner = "nixos";
    };
    sops.secrets.cachix-auth-token = {
      sopsFile = ../../../secrets/secrets.yaml;
      owner = "nixos";
      mode = "0400";
    };
    systemd.services.internal-gitops = let
      colmenaPkg = inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena;
      deployScript = pkgs.writeShellScript "deploy-fleet-wrapper" ''
        # Allow a "force run" without having to rewind git:
        # create /var/lib/internal-gitops/force then start internal-gitops.
        if [ -f /var/lib/internal-gitops/force ]; then
          export FORCE_UPDATE=1
          rm -f /var/lib/internal-gitops/force || true
        fi
        export DISCORD_WEBHOOK=$(cat ${config.sops.secrets.discord-webhook.path})
        export COLMENA_BIN="${colmenaPkg}/bin/colmena"
        if [ -f /run/secrets/cachix-auth-token ]; then
          export CACHIX_AUTH_TOKEN=$(cat /run/secrets/cachix-auth-token)
        fi
        exec ${pkgs.bash}/bin/bash ${../../../scripts/deploy-fleet.sh}
      '';
    in {
      description = "Internal GitOps: Pull and Deploy";
      # Prevent the service from restarting during activation (would kill the running script)
      stopIfChanged = false;
      restartIfChanged = false;
      path = [pkgs.git pkgs.openssh pkgs.cachix colmenaPkg pkgs.nix pkgs.curl pkgs.jq pkgs.gnugrep pkgs.gawk pkgs.gh "/run/wrappers"];
      serviceConfig = {
        EnvironmentFile = [
          config.sops.secrets.gh-token.path
        ];
        User = "nixos";
        Type = "oneshot";
        ExecStart = "${deployScript}";
        StateDirectory = "internal-gitops";
      };
    };

    systemd.timers.internal-gitops = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "60m"; # Check every 60 minutes
        RandomizedDelaySec = "1m";
      };
    };
  };
}
