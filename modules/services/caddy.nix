  { config, lib, pkgs, ... }:

  {
    options.caddy.enable = lib.mkEnableOption "Enable Caddy";

    config = lib.mkIf config.caddy.enable {
        sops.secrets.cf_api_token = {
    format   = "dotenv";
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
        environmentFile  = config.sops.secrets.cf_api_token.path;

        
      virtualHosts."nextcloud.hexaflare.net" = {
        extraConfig = ''
          route {
            reverse_proxy /outpost.goauthentik.io/* https://auth.hexaflare.net

            forward_auth https://auth.hexaflare.net {
                uri /outpost.goauthentik.io/auth/caddy
                copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Entitlements X-Authentik-Email X-Authentik-Name X-Authentik-Uid X-Authentik-Jwt X-Authentik-Meta-Jwks X-Authentik-Meta-Outpost X-Authentik-Meta-Provider X-Authentik-Meta-App X-Authentik-Meta-Version
                trusted_proxies private_ranges
            }

            reverse_proxy https://192.168.1.106:443 {
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

      virtualHosts."auth.hexaflare.net" = {
        extraConfig = ''
          reverse_proxy http://192.168.1.107:80
        '';
      };
    };
      
      networking.firewall.allowedTCPPorts = [ 443 80 ];
    };
  }

