{ config, modulesPath, pkgs, lib, ... }:

{

  imports = [ 
    (modulesPath + "/virtualisation/proxmox-lxc.nix") 
    ../../modules/system/autoUpgrade.nix
    ../../modules/services/openssh.nix
    ../../modules/nixpkgs/config.nix
    ];

  nix.settings = { sandbox = false; };  
  proxmoxLXC = {
    manageNetwork = false;
    privileged = true;
  };
    
  environment.systemPackages = with pkgs; [
    git
  ];
}