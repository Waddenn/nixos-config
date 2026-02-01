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
      owner = config.services.caddy.user;
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
        # Cloudflare IP ranges for trusted_proxies
        # https://www.cloudflare.com/ips/
        servers {
          trusted_proxies static private_ranges 173.245.48.0/20 103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 141.101.64.0/18 108.162.192.0/18 190.93.240.0/20 188.114.96.0/20 197.234.240.0/22 198.41.128.0/17 162.158.0.0/15 104.16.0.0/13 104.24.0.0/14 172.64.0.0/13 131.0.72.0/22 2606:4700::/32 2803:f800::/32 2405:b500::/32 2405:8100::/32 2a06:98c0::/29 2c0f:f248::/32
        }

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
        # "gitea.hexaflare.net" = {
        #   extraConfig =
        #     commonConfig
        #     + ''
        #       route {
        #         reverse_proxy /outpost.goauthentik.io/* http://192.168.40.107:80

        #         forward_auth http://192.168.40.107:80 {
        #           uri /outpost.goauthentik.io/auth/caddy
        #           copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Entitlements X-Authentik-Email X-Authentik-Name X-Authentik-Uid X-Authentik-Jwt X-Authentik-Meta-Jwks X-Authentik-Meta-Outpost X-Authentik-Meta-Provider X-Authentik-Meta-App X-Authentik-Meta-Version
        #         }

        #         reverse_proxy http://192.168.40.112:3000
        #       }
        #     '';
        # };
        # "linkwarden.hexaflare.net" = {
        #   extraConfig =
        #     commonConfig
        #     + ''
        #       reverse_proxy http://192.168.40.108:3000
        #     '';
        # };
        "bitwarden.hexaflare.net" = {
          extraConfig =
            commonConfig
            + ''
              reverse_proxy http://192.168.30.113:8222
            '';
        };
        # "auth.hexaflare.net" = {
        #   extraConfig =
        #     commonConfig
        #     + ''
        #       reverse_proxy http://192.168.40.107:80
        #     '';
        # };
        "homeassistant.hexaflare.net" = {
          extraConfig =
            commonConfig
            + ''
              reverse_proxy http://homeassistant:8123
            '';
        };
        # "bourse.hexaflare.net" = {
        #   extraConfig =
        #     commonConfig
        #     + ''
        #       reverse_proxy http://bourse-dashboard:5000
        #     '';
        # };
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
              reverse_proxy http://192.168.40.115:2283
            '';
        };
        # "glance.hexaflare.net" = {
        #   extraConfig =
        #     commonConfig
        #     + ''
        #       reverse_proxy http://glance:5678
        #     '';
        # };
      };
    };

    # Port 443 (HTTPS) exposed publicly
    # Port 2019 (Caddy metrics) is only accessible locally for monitoring
    networking.firewall.allowedTCPPorts = [443];

    # Increase UDP buffer sizes for QUIC performance
    # https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes
    boot.kernel.sysctl = {
      "net.core.rmem_max" = 7500000;
      "net.core.wmem_max" = 7500000;
    };
  };
}
