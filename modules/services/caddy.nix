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
            reverse_proxy https://192.168.1.106:443 {
                transport http {
                    tls_insecure_skip_verify
                }
            }
            tls {
                dns cloudflare {env.CF_API_TOKEN}
            }
          '';
        };
        
      };

      systemd.services.caddy.environment = {
        CF_API_TOKEN = "FEtkhJW0Ik9tVZPAvBSA2aBZV-Hd8527pBKm3S52";
      };

      networking.firewall.allowedTCPPorts = [ 443 ];
    };
  }
