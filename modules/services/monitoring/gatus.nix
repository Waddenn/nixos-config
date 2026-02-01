{
  config,
  lib,
  pkgs,
  ...
}: let
  # Generate Gatus endpoints from Caddy virtualHosts
  generateEndpoints = virtualHosts:
    lib.mapAttrsToList (domain: _vhostConfig: {
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
    virtualHosts;
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
        # Automatically generate endpoints from Caddy virtualHosts
        endpoints =
          if config.services.caddy.enable or false
          then generateEndpoints config.services.caddy.virtualHosts
          else [];
      };
    };
  };
}
