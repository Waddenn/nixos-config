{
  config,
  lib,
  pkgs,
  ...
}: {
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
        endpoints = [
          {
            name = "nextcloud";
            url = "https://nextcloud.hexaflare.net";
            conditions = ["[STATUS] == 200"];
            alerts = [
              {
                type = "discord";
                description = "nextcloud healthcheck failed";
                send-on-resolved = true;
              }
            ];
          }
          {
            name = "bitwarden";
            url = "https://bitwarden.hexaflare.net";
            conditions = ["[STATUS] == 200"];
            alerts = [
              {
                type = "discord";
                description = "bitwarden healthcheck failed";
                send-on-resolved = true;
              }
            ];
          }
          {
            name = "auth";
            url = "https://auth.hexaflare.net";
            conditions = ["[STATUS] == 200"];
            alerts = [
              {
                type = "discord";
                description = "auth healthcheck failed";
                send-on-resolved = true;
              }
            ];
          }
          {
            name = "bourse";
            url = "https://bourse.hexaflare.net";
            conditions = ["[STATUS] == 200"];
            alerts = [
              {
                type = "discord";
                description = "bourse healthcheck failed";
                send-on-resolved = true;
              }
            ];
          }
          {
            name = "gitea";
            url = "https://gitea.hexaflare.net";
            conditions = ["[STATUS] == 200"];
            alerts = [
              {
                type = "discord";
                description = "gitea healthcheck failed";
                send-on-resolved = true;
              }
            ];
          }
          {
            name = "homeassistant";
            url = "https://homeassistant.hexaflare.net";
            conditions = ["[STATUS] == 200"];
            alerts = [
              {
                type = "discord";
                description = "homeassistant healthcheck failed";
                send-on-resolved = true;
              }
            ];
          }

          {
            name = "jellyseerr";
            url = "https://jellyseerr.hexaflare.net";
            conditions = ["[STATUS] == 200"];
            alerts = [
              {
                type = "discord";
                description = "jellyseerr healthcheck failed";
                send-on-resolved = true;
              }
            ];
          }
        ];
      };
    };
  };
}
