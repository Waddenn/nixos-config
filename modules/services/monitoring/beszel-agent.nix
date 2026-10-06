{
  config,
  lib,
  pkgs,
  ...
}: let
  agent = pkgs.callPackage ../../../pkgs/beszel-agent.nix {};
  dockerEnabled = config.virtualisation.docker.enable;
in {
  options.my-services.monitoring.beszel-agent.enable = lib.mkEnableOption "Enable beszel-agent service";

  config = lib.mkIf config.my-services.monitoring.beszel-agent.enable {
    # Create a dedicated user for security
    users.users.beszel = {
      isSystemUser = true;
      group = "beszel";
      description = "Beszel Agent User";
    };
    users.groups.beszel = {};

    # Only the small local proxy can access the root-equivalent Docker socket.
    # The network-facing agent receives a filtered Unix socket instead.
    users.users.beszel-docker-proxy = lib.mkIf dockerEnabled {
      isSystemUser = true;
      group = "beszel";
      extraGroups = ["docker"];
    };
    systemd.services.beszel-docker-proxy = lib.mkIf dockerEnabled {
      description = "Read-only Docker API for Beszel";
      after = ["docker.service"];
      requires = ["docker.service"];
      serviceConfig = {
        ExecStart = "${pkgs.haproxy}/bin/haproxy -W -db -f ${./beszel-docker-proxy.cfg}";
        User = "beszel-docker-proxy";
        Group = "beszel";
        RuntimeDirectory = "beszel-docker-proxy";
        RuntimeDirectoryMode = "0750";
        Restart = "on-failure";
        UMask = "0077";
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateNetwork = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictNamespaces = true;
        # HAProxy probes IPv4/IPv6 socket options at startup even with a Unix
        # listener. PrivateNetwork keeps those sockets inside an empty netns.
        RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
        LockPersonality = true;
      };
    };

    systemd.services.beszel-agent = {
      description = "Beszel Agent Monitoring Service";
      wantedBy = ["multi-user.target"];
      after = ["network.target"] ++ lib.optional dockerEnabled "beszel-docker-proxy.service";
      requires = lib.optional dockerEnabled "beszel-docker-proxy.service";

      environment =
        {
          "KEY" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAC4vj5e821FKLnoBsMgHQvqOKbg7A/ACWMA8hUzQzy6";
          "PORT" = "45876";
        }
        // lib.optionalAttrs dockerEnabled {
          DOCKER_HOST = "unix:///run/beszel-docker-proxy/docker.sock";
        };

      serviceConfig = {
        ExecStart = "${agent}/bin/beszel-agent";
        Restart = "always";
        RestartSec = "10s";
        User = "beszel";
        Group = "beszel";
        StateDirectory = "beszel-agent";
        UMask = "0077";
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        InaccessiblePaths = lib.optionals dockerEnabled ["-/run/docker.sock"];
      };
    };

    networking.firewall.allowedTCPPorts = [45876];
  };
}
