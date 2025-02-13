{ config, lib, pkgs, ... }:

{
  options.caddy.enable = lib.mkEnableOption "Enable Caddy";

  config = lib.mkIf config.caddy.enable {

    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.0.0-20240703190432-89f16b99c18e" ];
        hash = "sha256-jCcSzenewQiW897GFHF9WAcVkGaS/oUu63crJu7AyyQ=";
      };

      logDir = "/var/log/caddy";
      dataDir = "/var/lib/caddy";

    virtualHosts."auth.hexaflare.net" = {
      extraConfig = ''
        tls {
          dns cloudflare {env.CF_API_TOKEN}
        }

        route {
          # Redirige vers le serveur Authentik en HTTPS
          reverse_proxy https://192.168.1.107:443 {
            transport http {
              tls_insecure_skip_verify
            }
            header_up Host {http.reverse_proxy.upstream.hostport}
          }

          # Ajoute les en-têtes nécessaires pour Authentik
          header_up X-Forwarded-Proto {scheme}
          header_up X-Forwarded-For {remote}
          header_up Host {host}
          header_up Upgrade {http_upgrade}
          header_up Connection {http_connection}
        }
      '';
    };
    };

    systemd.services.caddy.environment = {
      CF_API_TOKEN = "${config.sops.secrets.cf_api_token.path}";
    };

    networking.firewall.allowedTCPPorts = [ 443 80 ];
  };
}
