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
    lib.mapAttrsToList (domain: domainConfig:
      lib.optionalAttrs (domainConfig.monitoring or true) {
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
    domains;
in {
  options.gatus.enable = lib.mkEnableOption "Enable gatus";

  config = lib.mkIf config.gatus.enable {
    services.gatus = {
      enable = true;
      openFirewall = true;
      settings = {
        alerting = {
          discord = {
            webhook-url = "https://discord.com/api/webhooks/1200491254585241640/tE4ruyKKl2x_5TI60y_vJpqMoVub6zyM4yicWLGBy2UybZVd1ldqow7YHd1QwTX3gE1c";
          };
        };
        # Automatically generate endpoints from centralized domains configuration
        endpoints = generateEndpoints domainsConfig.domains;
      };
    };
  };
}
