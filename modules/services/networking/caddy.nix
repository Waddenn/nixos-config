{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my-services.networking.caddy;
  aopCA = ../../../lib/cloudflare-aop-ca.pem;
  aopClient = ../../../lib/cloudflare-aop-client.pem;
  cloudflareIPs = builtins.fromJSON (builtins.readFile ../../../lib/cloudflare-ips.json);
  cloudflareRanges = lib.concatStringsSep " " (cloudflareIPs.ipv4_cidrs ++ cloudflareIPs.ipv6_cidrs);
  declared = import ../../../lib/provisioned-services.nix {inherit lib;};
  internalRoutes = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: s: ''
      handle_path /${name}/* {
        reverse_proxy http://${s.hostname}.${declared.tailnet}:${toString s.application.port}
      }
    '')
    declared.proxyServices);
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
  tlsConfig = clientAuth:
    securityHeaders
    + ''
      tls {
        dns cloudflare {env.CF_API_TOKEN}
        ${lib.optionalString clientAuth ''
        client_auth {
          mode ${
          if cfg.requireOriginCertificate
          then "require_and_verify"
          else "verify_if_given"
        }
          trust_pool file ${aopCA}
        }
      ''}
      }
    '';
  commonConfig = tlsConfig false;
  # Check the TCP peer, never a visitor-controlled forwarded header. The route
  # preserves this check before forward_auth as well as the application proxy.
  cloudflareOnly = upstream:
    tlsConfig true
    + ''
      log_append aop_client_fingerprint {http.request.tls.client.fingerprint}
      route {
        @outsideCloudflare not remote_ip ${cloudflareRanges}
        respond @outsideCloudflare "Direct origin access is forbidden" 403
        ${upstream}
      }
    '';
in {
  options.my-services.networking.caddy = {
    enable = lib.mkEnableOption "Enable Caddy";
    requireOriginCertificate = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Require the dedicated Cloudflare origin client certificate after verifying its presentation.";
    };
  };

  config = lib.mkIf config.my-services.networking.caddy.enable {
    sops.secrets.cf_api_token = {
      sopsFile = ../../../secrets/secrets.yaml;
      owner = config.services.caddy.user;
      mode = "0400";
    };

    # Script pour générer le fichier d'environnement Caddy
    systemd.services.caddy-env-setup = {
      description = "Setup Caddy environment file with CF API token";
      before = ["caddy.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        mkdir -p /run/caddy
        cat > /run/caddy/env <<EOF
        CF_API_TOKEN=$(cat ${config.sops.secrets.cf_api_token.path})
        EOF
        chmod 600 /run/caddy/env
        chown ${config.services.caddy.user}:${config.services.caddy.group} /run/caddy/env
      '';
    };

    # Créer le répertoire /run/caddy
    systemd.tmpfiles.rules = [
      "d /run/caddy 0700 ${config.services.caddy.user} ${config.services.caddy.group} -"
    ];

    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = ["github.com/caddy-dns/cloudflare@v0.2.1"];
        hash = lib.removeSuffix "\n" (builtins.readFile ./caddy-plugin-hash.txt);
      };

      logDir = "/var/log/caddy";
      dataDir = "/var/lib/caddy";
      environmentFile = "/run/caddy/env";

      globalConfig = ''
        # Cloudflare IP ranges for trusted_proxies
        # https://www.cloudflare.com/ips/
        servers {
          strict_sni_host on
          trusted_proxies static private_ranges ${cloudflareRanges}
        }

        metrics {
          per_host
        }
      '';

      virtualHosts =
        lib.optionalAttrs (declared.proxyServices != {}) {
          "http://${declared.proxyHost}:${toString declared.proxyPort}".extraConfig = ''
            route {
              @outside not remote_ip 100.64.0.0/10
              respond @outside 403
              ${internalRoutes}
              respond 404
            }
          '';
        }
        // {
          "nextcloud.hexaflare.net" = {
            extraConfig =
              commonConfig
              + ''
                reverse_proxy http://192.168.40.116:80
              '';
          };
          "bitwarden.hexaflare.net" = {
            extraConfig = cloudflareOnly ''
              reverse_proxy http://192.168.30.113:8222
            '';
          };
          "auth.hexaflare.net" = {
            extraConfig = cloudflareOnly ''
              reverse_proxy http://192.168.40.123:9091 {
                header_up X-Forwarded-Proto {scheme}
                header_up X-Forwarded-Host {host}
                header_up X-Forwarded-Uri {uri}
                header_up X-Forwarded-For {remote_host}
              }
            '';
          };
          "homeassistant.hexaflare.net" = {
            extraConfig = cloudflareOnly ''
              reverse_proxy http://homeassistant:8123
            '';
          };
          "jellyseerr.hexaflare.net" = {
            extraConfig = cloudflareOnly ''
              reverse_proxy http://192.168.40.121:5055
            '';
          };
          "immich.hexaflare.net" = {
            extraConfig = cloudflareOnly ''
              reverse_proxy http://192.168.40.115:2283
            '';
          };
          "codex.hexaflare.net" = {
            extraConfig = cloudflareOnly ''
              forward_auth http://192.168.40.123:9091 {
                uri /api/authz/forward-auth
                copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
              }
              reverse_proxy https://100.124.126.44:6902 {
                transport http {
                  tls_insecure_skip_verify
                }
              }
            '';
          };
        };
    };

    # Port 443 (HTTPS) exposed publicly
    # Port 2019 (Caddy metrics) is only accessible locally for monitoring
    networking.firewall.allowedTCPPorts = [443];
    # No public listener allowance: this validation proxy is tailnet-only.
    networking.firewall.interfaces.tailscale0.allowedTCPPorts =
      lib.optional (declared.proxyServices != {}) declared.proxyPort;

    # Increase UDP buffer sizes for QUIC performance
    # https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes
    boot.kernel.sysctl = {
      "net.core.rmem_max" = 7500000;
      "net.core.wmem_max" = 7500000;
    };

    # Make Caddy wait for environment setup
    systemd.services.caddy = {
      after = ["caddy-env-setup.service"];
      requires = ["caddy-env-setup.service"];
    };

    # Public certificates only: the signing key and client key never reach Caddy.
    systemd.services.cloudflare-aop-expiry = {
      description = "Check Cloudflare origin authentication certificate expiry";
      serviceConfig = {
        Type = "oneshot";
        DynamicUser = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateNetwork = true;
      };
      script = ''
        ${pkgs.openssl}/bin/openssl x509 -checkend 5184000 -noout -in ${aopClient}
        ${pkgs.openssl}/bin/openssl x509 -checkend 5184000 -noout -in ${aopCA}
      '';
    };
    systemd.timers.cloudflare-aop-expiry = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}
