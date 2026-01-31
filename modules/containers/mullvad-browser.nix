{ config, lib, pkgs, ... }: {
  options.my-services.containers.mullvad-browser.enable = lib.mkEnableOption "mullvad-browser container";

  config = lib.mkIf config.my-services.containers.mullvad-browser.enable {
    virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      mullvad-browser = {
        image = "lscr.io/linuxserver/mullvad-browser:latest";
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "Europe/Paris";
        };
        volumes = [
          "/var/lib/mullvad-browser/config:/config"
          "/var/lib/mullvad-browser/data:/data"
        ];
        ports = [
          "3000:3000"
          "3001:3001"
        ];
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [3000 3001];
  };
  };
}
