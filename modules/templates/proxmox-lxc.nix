{ config, modulesPath, pkgs, lib, ... }:

{

  imports = [ 
    (modulesPath + "/virtualisation/proxmox-lxc.nix") 
    ../system/autoUpgrade.nix
    ../services/openssh.nix
    ../nixpkgs/config.nix
    ../modules/nix/settings.nix
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
  ];
}