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

        virtualHosts."calibre.hexaflare.net" = {
          extraConfig = ''
            reverse_proxy 192.168.1.110:8081
            tls internal
          '';
        };

      };

          systemd.services.caddy.environment = {
        CF_API_TOKEN = "pnnLB5d5QErdTD-t5RS1PDrqYHlXvRlAisRvx1Fa";
      };

      networking.firewall.allowedTCPPorts = [ 443 ];
    };
  }
