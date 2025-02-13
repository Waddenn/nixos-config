{ config, lib, pkgs, ... }:

{
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare" ];
    };

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

    # Variables d'environnement pour le DNS challenge
    environment = {
      CF_API_TOKEN = "${config.sops.secrets.cf_api_token.path}";
    };
  };

  # Ouvre les ports nécessaires sur le pare-feu
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
