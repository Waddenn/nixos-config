{ config, lib, pkgs, ... }:

{
  options.caddy.enable = lib.mkEnableOption "Enable Caddy";

  config = lib.mkIf config.caddy.enable {

    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.0.0-20240703190432-89f16b99c18e" ];
        hash = "sha256-JVkUkDKdat4aALJHQCq1zorJivVCdyBT+7UhqTvaFLw=";
      };

      logDir = "/var/log/caddy";
      dataDir = "/var/lib/caddy";

      virtualHosts."test.hexaflare.net" = {
        extraConfig = ''
          tls {
            dns cloudflare env:CLOUDFLARE_API_KEY
          }
          reverse_proxy http://192.168.1.107:80 {
          }
        '';
      };

    };

    networking.firewall.allowedTCPPorts = [ 443 80 ];

    systemd.services.caddy.serviceConfig.EnvironmentFile = "/etc/environment";

  };
}
