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
          handle_path /outpost.goauthentik.io/* {
              forward_auth https://192.168.1.107:443 {
                  uri /outpost.goauthentik.io/auth/caddy
                  copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Email X-Authentik-Uid X-Authentik-Jwt
                  header_up Host {http.reverse_proxy.upstream.hostport}
              }
              reverse_proxy https://192.168.1.107:443 {
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

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
