{
  config,
  modulesPath,
  pkgs,
  lib,
  ...
}: {
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

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
    python3
  ];

  my-services.networking.tailscale = {
    enable = true;
    role = "server";
  };

  my-services.networking.openssh.enable = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  fish.enable = true;
  documentation.man.enable = false;
  beszel-agent.enable = true; # Need to standardize beszel too? Later.
  time.timeZone = "Europe/Paris";
  system.stateVersion = "25.05";

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
}
