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
              reverse_proxy /outpost.goauthentik.io/* http://192.168.1.107:80 {
                  header_up X-Forwarded-Proto {scheme}
                  header_up X-Forwarded-For {remote}
                  header_up Host {host}
                  header_up Connection "Upgrade"
                  header_up Upgrade {upstream_http_upgrade}
              }

              forward_auth http://192.168.1.107:80 {
                  uri /outpost.goauthentik.io/auth/caddy
                  copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Email X-Authentik-Uid X-Authentik-Jwt
                  transport http {
                      tls
                      tls_insecure_skip_verify
                  }
              }

              reverse_proxy http://192.168.1.107:80 {
                  header_up X-Forwarded-Proto {scheme}
                  header_up X-Forwarded-For {remote}
                  header_up Host {host}
                  header_up Connection "Upgrade"
                  header_up Upgrade {upstream_http_upgrade}
              }
          }
        '';
      };

      virtualHosts."nextcloud.hexaflare.net" = {
        extraConfig = ''
          tls {
              dns cloudflare {env.CF_API_TOKEN}
          }

          route {
              reverse_proxy https://192.168.1.106:443 {
                  transport http {
                      tls_insecure_skip_verify
                  }
                  header_up X-Forwarded-Proto {scheme}
                  header_up X-Forwarded-For {remote}
                  header_up Host {host}
                  header_up Connection "Upgrade"
                  header_up Upgrade {upstream_http_upgrade}
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
