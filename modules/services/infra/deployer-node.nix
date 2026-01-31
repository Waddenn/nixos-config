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
        export DISCORD_WEBHOOK=$(cat ${config.sops.secrets.discord-webhook.path})
        export COLMENA_BIN="${colmenaPkg}/bin/colmena"
        exec ${pkgs.bash}/bin/bash ${../../../scripts/deploy-fleet.sh}
      '';
    in {
      description = "Internal GitOps: Pull and Deploy";
      # Prevent the service from restarting during activation (would kill the running script)
      stopIfChanged = false;
      restartIfChanged = false;
      path = [pkgs.git pkgs.openssh colmenaPkg pkgs.nix pkgs.curl pkgs.jq pkgs.gnugrep pkgs.gawk pkgs.gh "/run/wrappers"];
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
