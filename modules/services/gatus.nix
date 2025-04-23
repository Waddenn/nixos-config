{ config, lib, pkgs, ... }:

{
  options.gatus.enable = lib.mkEnableOption "Enable gatus";

  config = lib.mkIf config.gatus.enable {
    services.gatus = {
      enable = true;
      openFirewall = true;
      settings = {
        endpoints = [
          {
            name = "nextcloud";
            url = "https://nextcloud.hexaflare.net";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "bitwarden";
            url = "https://bitwarden.hexaflare.net";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "auth";
            url = "https://auth.hexaflare.net";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "bourse";
            url = "https://bourse.hexaflare.net";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "gitea";
            url = "https://gitea.hexaflare.net";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "homeassistant";
            url = "https://homeassistant.hexaflare.net";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "linkwarden";
            url = "https://linkwarden.hexaflare.net";
            conditions = [ "[STATUS] == 200" ];
          }
        ];
      };
    };
  };
}
