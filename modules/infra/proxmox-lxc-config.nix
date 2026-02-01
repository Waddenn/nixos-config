{
  config,
  modulesPath,
  pkgs,
  lib,
  ...
}: {
  options.my-services.infra.proxmox-lxc.enable = lib.mkEnableOption "Proxmox LXC Configuration";

  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  config = lib.mkIf config.my-services.infra.proxmox-lxc.enable {
    boot.isContainer = true;
    systemd.suppressedSystemUnits = [
      "dev-mqueue.mount"
      "sys-kernel-debug.mount"
      "sys-fs-fuse-connections.mount"
    ];

    nix.settings = {
      sandbox = false;
      trusted-users = ["root" "@wheel"];
    };
    proxmoxLXC = {
      manageNetwork = false;
      privileged = true;
    };

    security.sudo.wheelNeedsPassword = false;

    environment.systemPackages = with pkgs; [
      git
      just
    ];

    my-services.networking.tailscale = {
      enable = true;
      role = "server";
    };

    my-services.networking.openssh.enable = true;
    nix.settings.experimental-features = ["nix-command" "flakes"];
    my-services.programs.fish.enable = true;
    documentation.man.enable = false;
    my-services.monitoring.beszel-agent.enable = true; # Need to standardize beszel too? Later.
    time.timeZone = "Europe/Paris";
    sops.defaultSopsFile = ../../secrets/secrets.yaml;
    sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    system.stateVersion = "25.05";

    nixpkgs = {
      config = {
        allowUnfree = true;
      };
    };
  };
}
