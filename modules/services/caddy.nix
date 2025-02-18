{ config, lib, pkgs, ... }:

let
  securityHeaders = ''
    header {
      Server "Secure-Proxy"
      -X-Powered-By
      Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
      X-Frame-Options "DENY"
      X-Content-Type-Options "nosniff"
      X-XSS-Protection "1; mode=block"
      Referrer-Policy "strict-origin-when-cross-origin"
      Permissions-Policy "geolocation=(), microphone=(), camera=()"
    }
  '';

in {
  options.caddy.enable = lib.mkEnableOption "Enable Caddy";

  config = lib.mkIf config.caddy.enable {
    sops.secrets.cf_api_token = {
      format = "dotenv";
      sopsFile = ../../secrets/cf_api_token.env.enc;
    };

    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.0.0-20240703190432-89f16b99c18e" ];
        hash = "sha256-JVkUkDKdat4aALJHQCq1zorJivVCdyBT+7UhqTvaFLw=";
      };

      logDir = "/var/log/caddy";
      dataDir = "/var/lib/caddy";
      environmentFile = config.sops.secrets.cf_api_token.path;

      virtualHosts = {
        "nextcloud.hexaflare.net" = {
          extraConfig = securityHeaders + ''
            route {
              reverse_proxy /outpost.goauthentik.io/* http://192.168.20.107:80

              forward_auth http://192.168.20.107:80 {
                uri /outpost.goauthentik.io/auth/caddy
                copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Entitlements X-Authentik-Email X-Authentik-Name X-Authentik-Uid X-Authentik-Jwt X-Authentik-Meta-Jwks X-Authentik-Meta-Outpost X-Authentik-Meta-Provider X-Authentik-Meta-App X-Authentik-Meta-Version
              }

              reverse_proxy https://192.168.20.106:443 {
                transport http {
                  tls_insecure_skip_verify
                }
              }
            }

            tls {
              dns cloudflare {env.CF_API_TOKEN}
            }
          '';
        };
        "gitea.hexaflare.net" = {
          extraConfig = securityHeaders + ''
            route {
              reverse_proxy /outpost.goauthentik.io/* http://192.168.20.107:80

              forward_auth http://192.168.20.107:80 {
                uri /outpost.goauthentik.io/auth/caddy
                copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Entitlements X-Authentik-Email X-Authentik-Name X-Authentik-Uid X-Authentik-Jwt X-Authentik-Meta-Jwks X-Authentik-Meta-Outpost X-Authentik-Meta-Provider X-Authentik-Meta-App X-Authentik-Meta-Version
              }

              reverse_proxy http://192.168.20.112:3000
            }

            tls {
              dns cloudflare {env.CF_API_TOKEN}
            }
          '';
        };
        "linkwarden.hexaflare.net" = {
          extraConfig = securityHeaders + ''
            reverse_proxy http://192.168.20.108:3000
          '';
        };
        "auth.hexaflare.net" = {
          extraConfig = securityHeaders + ''
            reverse_proxy http://192.168.20.107:80
          '';
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 443 ];
  };
}
