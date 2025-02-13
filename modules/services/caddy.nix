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

      # virtualHosts."nextcloud.hexaflare.net" = {
      #   extraConfig = ''
      #     tls {
      #         dns cloudflare {env.CF_API_TOKEN}
      #     }
      #     route {
      #         reverse_proxy /outpost.goauthentik.io/* http://192.168.1.107:80
      #         forward_auth http://192.168.1.107:80 {
      #             uri /outpost.goauthentik.io/auth/caddy
      #             copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Email X-Authentik-Uid X-Authentik-Jwt
      #             trusted_proxies private_ranges
      #         }
      #         reverse_proxy https://192.168.1.106:443 {
      #             transport http {
      #                 tls_insecure_skip_verify
      #             }
      #         }
      #     }
      #   '';
      # };

      virtualHosts."auth.hexaflare.net" = {
        extraConfig = ''
          tls {
              dns cloudflare {env.CF_API_TOKEN}
          }
              reverse_proxy http://192.168.1.107 {
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
Feb 13 09:43:18 caddy caddy[55420]: {"level":"error","ts":1739439798.973226,"logger":"tls.obtain","msg":"could not get certificate from issuer","identifier":"auth.hexaflare.net","issuer":"acme-v02.api.letsencrypt.org-directory","error":"[auth.hexaflare.net] solving challenges: presenting for challenge: adding temporary record for zone \"hexaflare.net.\": got error status: HTTP 400: [{Code:6003 Message:Invalid request headers ErrorChain:[{Code:6111 Message:Invalid format for Authorization header}]}] (order=https://acme-staging-v02.api.letsencrypt.org/acme/order/184241564/22585932244) (ca=https://acme-staging-v02.api.letsencrypt.org/directory)"}
Feb 13 09:43:18 caddy caddy[55420]: {"level":"error","ts":1739439798.9732668,"logger":"tls.obtain","msg":"will retry","error":"[auth.hexaflare.net] Obtain: [auth.hexaflare.net] solving challenges: presenting for challenge: adding temporary record for zone \"hexaflare.net.\": got error status: HTTP 400: [{Code:6003 Message:Invalid request headers ErrorChain:[{Code:6111 Message:Invalid format for Authorization header}]}] (order=https://acme-staging-v02.api.letsencrypt.org/acme/order/184241564/22585932244) (ca=https://acme-staging-v02.api.letsencrypt.org/directory)","attempt":4,"retrying_in":300,"elapsed":306.165131977,"max_duration":2592000}
Feb 13 09:47:21 caddy systemd[1]: Reloading Caddy...
Feb 13 09:47:21 caddy caddy[108080]: {"level":"info","ts":1739440041.9002588,"msg":"using config from file","file":"/etc/caddy/caddy_config"}
Feb 13 09:47:21 caddy caddy[108080]: Error: adapting config using caddyfile: subject does not qualify for certificate: '}'
Feb 13 09:47:21 caddy systemd[1]: caddy.service: Control process exited, code=exited, status=1/FAILURE
Feb 13 09:47:21 caddy systemd[1]: Reload failed for Caddy.
