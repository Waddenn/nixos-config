{
  config,
  modulesPath,
  pkgs,
  lib,
  ...
}: {
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ../../modules/default.nix
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
  ];

  python3Minimal.enable = true;
  tailscale-server.enable = true;
  gitAutoPull.enable = true;
  autoUpgrade.enable = false;
  openssh.enable = true;
  allowUnfree.enable = true;
  experimental-features.enable = true;
  zsh.enable = true;
  gc.enable = true;
  beszel-agent.enable = true;
  time.timeZone = "Europe/Paris";
  system.stateVersion = "25.05";
}
