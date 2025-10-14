{
  config,
  modulesPath,
  pkgs,
  lib,
  ...
}: {
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ../../modules
    ../../themes/nixy.nix
  ];

  boot.isContainer = true;
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  nix.settings = {sandbox = false;};
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

  tailscale-server.enable = true;
  gitAutoPull.enable = true;
  autoUpgrade.enable = true;
  openssh.enable = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  fish.enable = true;
  documentation.man.enable = false;
  beszel-agent.enable = true;
  time.timeZone = "Europe/Paris";
  system.stateVersion = "25.05";

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    persistent = true;
    options = "--delete-older-than 14d";
  };
}
