{
  config,
  lib,
  pkgs,
  ...
}: {
  options.beszel-agent.enable = lib.mkEnableOption "Enable beszel-agent service";

  config = lib.mkIf config.beszel-agent.enable {
    # Create a dedicated user for security
    users.users.beszel = {
      isSystemUser = true;
      group = "beszel";
      description = "Beszel Agent User";
      # If docker is enabled on the host, allow beszel to access the socket for container stats
      extraGroups = lib.optionals config.virtualisation.docker.enable ["docker"];
    };
    users.groups.beszel = {};

    systemd.services.beszel-agent = {
      description = "Beszel Agent Monitoring Service";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      
      environment = {
        "KEY" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAC4vj5e821FKLnoBsMgHQvqOKbg7A/ACWMA8hUzQzy6";
        "PORT" = "45876";
      };

      serviceConfig = {
        ExecStart = "${pkgs.beszel}/bin/beszel-agent";
        Restart = "always";
        RestartSec = "10s";
        User = "beszel";
        Group = "beszel";
      };
    };

    networking.firewall.allowedTCPPorts = [45876];
  };
}
