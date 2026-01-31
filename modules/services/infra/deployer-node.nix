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
    };
    sops.secrets.discord-webhook = {
      sopsFile = ../../../secrets/secrets.yaml;
    };
    sops.templates."discord-gitops.env".content = ''
      DISCORD_WEBHOOK=''${config.sops.placeholder.discord-webhook}
    '';
    systemd.services.internal-gitops = let
      colmenaPkg = inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena;
    in {
      description = "Internal GitOps: Pull and Deploy";
      # Prevent the service from restarting during activation (would kill the running script)
      stopIfChanged = false;
      path = [pkgs.git pkgs.openssh colmenaPkg pkgs.nix pkgs.curl pkgs.jq pkgs.gnugrep pkgs.gawk pkgs.gh "/run/wrappers"];
      script = builtins.readFile ../../../scripts/deploy-fleet.sh;
      serviceConfig = {
        EnvironmentFile = [
          config.sops.secrets.gh-token.path
          config.sops.templates."discord-gitops.env".path
        ];
        User = "nixos";
        Type = "oneshot";
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
