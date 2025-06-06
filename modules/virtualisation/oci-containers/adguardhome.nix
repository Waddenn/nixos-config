# Auto-generated using compose2nix v0.3.2-pre.
{
  pkgs,
  lib,
  ...
}: {
  # Runtime
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "docker";

  # Containers
  virtualisation.oci-containers.containers."adguardhome" = {
    image = "adguard/adguardhome";
    volumes = [
      "/home/nixos/adguardhome/confdir:/opt/adguardhome/conf:rw"
      "/home/nixos/adguardhome/workdir:/opt/adguardhome/work:rw"
    ];
    ports = [
      "53:53/tcp"
      "53:53/udp"
      "784:784/udp"
      "853:853/tcp"
      "3000:3000/tcp"
      "80:80/tcp"
      "443:443/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=adguardhome"
      "--network=adguardhome_default"
    ];
  };
  systemd.services."docker-adguardhome" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-adguardhome_default.service"
    ];
    requires = [
      "docker-network-adguardhome_default.service"
    ];
    partOf = [
      "docker-compose-adguardhome-root.target"
    ];
    wantedBy = [
      "docker-compose-adguardhome-root.target"
    ];
  };

  # Networks
  systemd.services."docker-network-adguardhome_default" = {
    path = [pkgs.docker];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f adguardhome_default";
    };
    script = ''
      docker network inspect adguardhome_default || docker network create adguardhome_default
    '';
    partOf = ["docker-compose-adguardhome-root.target"];
    wantedBy = ["docker-compose-adguardhome-root.target"];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."docker-compose-adguardhome-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = ["multi-user.target"];
  };
}
