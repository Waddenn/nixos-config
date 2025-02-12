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

      virtualHosts."nextcloud.hexaflare.net" = {
        extraConfig = ''
          route {
              # Redirige les requêtes d'authentification vers Authentik
              reverse_proxy /outpost.goauthentik.io/* http://192.168.1.107:80

              # Authentification obligatoire via Authentik
              forward_auth nextcloud.hexaflare.net {
                  uri /outpost.goauthentik.io/auth/caddy
                  copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Email X-Authentik-Uid X-Authentik-Jwt
                  trusted_proxies private_ranges
              }

              # Reverse Proxy vers Nextcloud
              reverse_proxy https://192.168.1.106:443 {
                  transport http {
                      tls_insecure_skip_verify
                  }
              }
          }

          # TLS avec Cloudflare DNS
          tls {
              dns cloudflare {env.CF_API_TOKEN}
          }
        '';
      };
    };

    # Ajout de l'API Token Cloudflare
    systemd.services.caddy.environment = {
      CF_API_TOKEN = "${config.sops.secrets.cf_api_token.path}";
    };

    # Ouverture du port HTTPS
    networking.firewall.allowedTCPPorts = [ 443 ];
  };
}
