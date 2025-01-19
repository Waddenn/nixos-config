{ config, modulesPath, pkgs, lib, inputs, ... }:

{

  imports = [ 
    (modulesPath + "/virtualisation/proxmox-lxc.nix") 
    ../global.nix
    ];


  boot.isContainer = true;
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  nix.settings = { sandbox = false; };  
  proxmoxLXC = {
    manageNetwork = false;
    privileged = true;
  };
    
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    sops
    just
  ];

  autoUpgrade.enable = true;
  openssh.enable = true;
  allowUnfree.enable = true;
  experimental-features.enable = true;
  zsh.enable = true;
}