{
  config,
  lib,
  pkgs,
  ...
}: let
  securityHeaders = ''
    header {
      Server "Secure-Proxy"
      -X-Powered-By
      Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
      X-Frame-Options "SAMEORIGIN"
      X-Content-Type-Options "nosniff"
      X-XSS-Protection "1; mode=block"
      Referrer-Policy "strict-origin-when-cross-origin"
      Permissions-Policy "geolocation=(), microphone=(), camera=()"
    }
  '';
  commonConfig =
    securityHeaders
    + ''
      tls {
        dns cloudflare {env.CF_API_TOKEN}
      }
    '';
in {
  options.my-services.networking.caddy.enable = lib.mkEnableOption "Enable Caddy";

  config = lib.mkIf config.my-services.networking.caddy.enable {
    sops.secrets.cf_api_token = {
      format = "dotenv";
      sopsFile = ../../../secrets/cf_api_token.env.enc;
    };

    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = ["github.com/caddy-dns/cloudflare@v0.2.1"];
        hash = "sha256-Zls+5kWd/JSQsmZC4SRQ/WS+pUcRolNaaI7UQoPzJA0=";
      };

      logDir = "/var/log/caddy";
      dataDir = "/var/lib/caddy";
      environmentFile = config.sops.secrets.cf_api_token.path;

      globalConfig = ''
        metrics {
          per_host
        }
      '';

      virtualHosts = {
        "nextcloud.hexaflare.net" = {
          extraConfig =
            commonConfig
            + ''
              reverse_proxy http://192.168.40.116:80
            '';
        };
        "gitea.hexaflare.net" = {
          extraConfig =
            commonConfig
            + ''
              route {
                reverse_proxy /outpost.goauthentik.io/* http://192.168.40.107:80

                forward_auth http://192.168.40.107:80 {
                  uri /outpost.goauthentik.io/auth/caddy
                  copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Entitlements X-Authentik-Email X-Authentik-Name X-Authentik-Uid X-Authentik-Jwt X-Authentik-Meta-Jwks X-Authentik-Meta-Outpost X-Authentik-Meta-Provider X-Authentik-Meta-App X-Authentik-Meta-Version
                }

                reverse_proxy http://192.168.40.112:3000
              }
            '';
        };
        "linkwarden.hexaflare.net" = {
          extraConfig =
            commonConfig
            + ''
              reverse_proxy http://192.168.40.108:3000
            '';
        };
        "bitwarden.hexaflare.net" = {
          extraConfig =
            commonConfig
            + ''
              reverse_proxy http://192.168.30.113:8222
            '';
        };
        "auth.hexaflare.net" = {
          extraConfig =
            commonConfig
            + ''
              reverse_proxy http://192.168.40.107:80
            '';
        };
        "homeassistant.hexaflare.net" = {
          extraConfig =
            commonConfig
            + ''
              reverse_proxy http://homeassistant:8123
            '';
        };
        "bourse.hexaflare.net" = {
          extraConfig =
            commonConfig
            + ''
              reverse_proxy http://bourse-dashboard:5000
            '';
        };
        "jellyseerr.hexaflare.net" = {
          extraConfig =
            commonConfig
            + ''
              reverse_proxy http://192.168.40.121:5055
            '';
        };
        "immich.hexaflare.net" = {
          extraConfig =
            commonConfig
            + ''
              reverse_proxy http://immich:2283
            '';
        };
        "glance.hexaflare.net" = {
          extraConfig =
            commonConfig
            + ''
              reverse_proxy http://glance:5678
            '';
        };
      };
    };

    networking.firewall.allowedTCPPorts = [443 2019];
  };
}
