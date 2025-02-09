{ config, lib, pkgs, ... }:

{
  options.caddy.enable = lib.mkEnableOption "Enable caddy";

  config = lib.mkIf config.caddy.enable {

  services.caddy = {
    enable = true;  
    logDir = "/var/log/caddy";  
    dataDir = "/var/lib/caddy"; 
    virtualHosts."hexaflare.net".extraConfig = ''
    reverse_proxy http://192.168.1.110:8081
    tls {
        dns cloudflare {env.CF_API_TOKEN}  
      }
  '';
  };

  };
}
