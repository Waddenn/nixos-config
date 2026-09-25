{
  config,
  lib,
  pkgs,
  service,
  ...
}: {
  imports = [./bootstrap.nix];
  environment.systemPackages = [pkgs.curl];
  networking.hostName = lib.mkOverride 40 service.hostname;
  sops = {
    defaultSopsFile = service.secretFile;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  };
  services.tailscale = {
    enable = true;
    # No privileged /dev/net/tun bind or Proxmox feature update is required.
    interfaceName = "userspace-networking";
    extraSetFlags = ["--accept-dns=false"];
  };
  services.gatus = lib.mkIf service.monitoring {
    enable = true;
    settings = {
      web = {
        address = "127.0.0.1";
        port = 8081;
      };
      endpoints = [
        {
          name = service.name;
          group = "pilot";
          url = "http://127.0.0.1:${toString service.application.port}${service.application.healthPath}";
          interval = "5s";
          conditions = service.application.conditions;
        }
      ];
    };
  };
}
