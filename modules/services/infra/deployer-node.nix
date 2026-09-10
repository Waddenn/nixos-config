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
    systemd.services.internal-gitops = let
      colmenaPkg = inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena;
      deployScript = pkgs.writeShellScript "deploy-fleet-wrapper" ''
        set -euo pipefail
        rm -f /var/lib/internal-gitops/force
        export DISCORD_WEBHOOK=$(cat ${config.sops.secrets.discord-webhook.path})
        export NOTIFICATION_STATE_FILE=/var/lib/internal-gitops/last-discord-notification.json
        export COLMENA_BIN="${colmenaPkg}/bin/colmena"
        exec ${pkgs.python3}/bin/python3 ${../../../scripts/fleet.py}
      '';
    in {
      description = "Colmena fleet reconciliation with CI and canary gates";
      # Prevent the service from restarting during activation (would kill the running script)
      stopIfChanged = false;
      restartIfChanged = false;
      path = [pkgs.python3 pkgs.coreutils pkgs.util-linux pkgs.bash pkgs.git pkgs.openssh colmenaPkg pkgs.nix pkgs.curl pkgs.jq pkgs.gnugrep pkgs.gawk pkgs.gh "/run/wrappers"];
      serviceConfig = {
        EnvironmentFile = [
          config.sops.secrets.gh-token.path
        ];
        User = "nixos";
        Type = "oneshot";
        TimeoutStartSec = "4h";
        UMask = "0077";
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
