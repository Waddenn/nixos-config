{ config, lib, pkgs, ... }:

{
  options.gatus.enable = lib.mkEnableOption "Enable gatus";

  config = lib.mkIf config.gatus.enable {
    services.gatus = {
      enable = true;
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
            name = "proxmox";
            url = "http://192.168.1.1:8006";
            conditions = [ "[STATUS] == 200" ];
          }
        ];
      };
      services.gatus.openFirewall = true;
    };
  };
}
