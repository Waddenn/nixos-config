{
  config,
  lib,
  pkgs,
  ...
}: let
  # Import centralized domain configuration
  domainsConfig = import ../../../lib/domains.nix;

  # Generate Gatus endpoints from centralized domains
  generateEndpoints = domains:
    lib.mapAttrsToList (domain: domainConfig: {
      name = builtins.replaceStrings [".hexaflare.net"] [""] domain;
      url = "https://${domain}";
      conditions = ["[STATUS] == 200"];
      alerts = [
        {
          type = "discord";
          description = "${domain} healthcheck failed";
          send-on-resolved = true;
        }
      ];
    })
    (lib.filterAttrs (_: value: value.monitoring or true) domains);
in {
  options.my-services.monitoring.gatus.enable = lib.mkEnableOption "Enable gatus";

  config = lib.mkIf config.my-services.monitoring.gatus.enable {
    sops.secrets.discord-webhook = {
      sopsFile = ../../../secrets/secrets.yaml;
      restartUnits = ["gatus-env.service" "gatus.service"];
    };
    systemd.services.gatus-env = {
      before = ["gatus.service"];
      requiredBy = ["gatus.service"];
      after = ["sops-nix.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        RuntimeDirectory = "gatus-alerting";
        RuntimeDirectoryMode = "0700";
        UMask = "0077";
      };
      script = ''
        value=$(cat ${config.sops.secrets.discord-webhook.path})
        case "$value" in
          discord://*)
            value="''${value#discord://}"
            value="https://discord.com/api/webhooks/''${value##*@}/''${value%@*}"
            ;;
        esac
        printf 'DISCORD_WEBHOOK=%s\n' "$value" > /run/gatus-alerting/environment
      '';
    };
    services.gatus = {
      environmentFile = "/run/gatus-alerting/environment";
      enable = true;
      openFirewall = true;
      settings = {
        alerting = {
          discord = {
            webhook-url = "\${DISCORD_WEBHOOK}";
          };
        };
        # Automatically generate endpoints from centralized domains configuration
        endpoints = generateEndpoints domainsConfig.domains;
      };
    };
  };
}
