{ config, lib, ... }:

{
  options.caddy.enable = lib.mkEnableOption "Enable caddy";

  config = lib.mkIf config.caddy.enable {

  services.caddy = {
    enable = true;
    virtualHosts."calibre.hexaflare.net".extraConfig = ''
      reverse_proxy http://192.168.1.122:8080
    '';
  };

  };
}
