{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my-services.infra.opnsense-maintenance;
  policy = builtins.fromJSON (builtins.readFile ../../../opnsense/hardening/policy.json);
  issuer = pkgs.writeText "opnsense-certificate-issuer.json" (builtins.toJSON {
    admin.disabled = true;
    apps.tls = {
      certificates.automate = [policy.domain];
      automation.policies = [
        {
          subjects = [policy.domain];
          issuers = [
            {
              module = "acme";
              challenges.dns.provider = {
                name = "cloudflare";
                api_token = "{env.CF_API_TOKEN}";
              };
            }
          ];
        }
      ];
    };
  });
in {
  options.my-services.infra.opnsense-maintenance = {
    issuer = lib.mkEnableOption "Private OPNsense DNS-challenge certificate issuer";
    controller = lib.mkEnableOption "Encrypted OPNsense backups, logs and certificate delivery";
  };
  config = lib.mkMerge [
    (lib.mkIf cfg.issuer {
      assertions = [
        {
          assertion = config.my-services.networking.caddy.enable;
          message = "OPNsense certificate issuer requires the existing Caddy DNS integration";
        }
      ];
      systemd.services.opnsense-certificate = {
        description = "Issue and renew private OPNsense certificate without an HTTP listener";
        wantedBy = ["multi-user.target"];
        wants = ["network-online.target"];
        after = ["network-online.target" "caddy-env-setup.service"];
        requires = ["caddy-env-setup.service"];
        environment = {
          XDG_DATA_HOME = "/var/lib/opnsense-certificate";
          XDG_CONFIG_HOME = "/var/lib/opnsense-certificate/config";
        };
        serviceConfig = {
          User = config.services.caddy.user;
          Group = config.services.caddy.group;
          EnvironmentFile = "/run/caddy/env";
          StateDirectory = "opnsense-certificate";
          StateDirectoryMode = "0700";
          UMask = "0077";
          ExecStart = "${config.services.caddy.package}/bin/caddy run --config ${issuer}";
          Restart = "on-failure";
          RestartSec = "30s";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
          PrivateDevices = true;
        };
      };
    })
    (lib.mkIf cfg.controller {
      programs.ssh.knownHosts.opnsense-native = {
        hostNames = ["opnsense-native"];
        publicKey = policy.native_ssh_host_key;
      };
      systemd.services.opnsense-maintenance = {
        description = "Collect encrypted OPNsense backups and logs, renew certificate, check health";
        wants = ["network-online.target"];
        after = ["network-online.target"];
        path = [pkgs.openssh];
        serviceConfig = {
          Type = "oneshot";
          User = "nixos";
          UMask = "0077";
          StateDirectory = "opnsense-maintenance";
          StateDirectoryMode = "0700";
          TimeoutStartSec = "10m";
          ExecStart = "${pkgs.python3}/bin/python3 ${../../../opnsense/hardening/collect.py} --state-dir /var/lib/opnsense-maintenance";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = "read-only";
          PrivateDevices = true;
        };
      };
      systemd.timers.opnsense-maintenance = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "15m";
          OnUnitActiveSec = "1h";
          RandomizedDelaySec = "5m";
          Persistent = true;
        };
      };
    })
  ];
}
