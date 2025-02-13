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

              reverse_proxy /outpost.goauthentik.io/* http://192.168.1.107:80
              header_up Host {http.reverse_proxy.upstream.hostport}
              forward_auth auth.hexaflare.net {
                  uri /outpost.goauthentik.io/auth/caddy
                copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Email X-Authentik-Name X-Authentik-Uid X-Authentik-Jwt X-Authentik-Meta-Jwks X-Authentik-Meta-Outpost X-Authentik-Meta-Provider X-Authentik-Meta-App X-Authentik-Meta-Version X-Forwarded-Host Authorization                  trusted_proxies private_ranges
              }
              reverse_proxy https://192.168.1.106:443 {
                  transport http {
                      tls_insecure_skip_verify
                  }
              }
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
