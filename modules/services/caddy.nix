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
              dns cloudflare {$CLOUDFLARE_API_TOKEN}
            }
            reverse_proxy http://192.168.1.107:80 {
            }
          '';
        };

      };
    systemd.services.caddy = {
      serviceConfig.Environment = "CLOUDFLARE_API_TOKEN=${config.sops.secrets.cloudflare_token}";
    };
      networking.firewall.allowedTCPPorts = [ 443 80 ];
    };
  }

