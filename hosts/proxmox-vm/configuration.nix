
{ config, pkgs, ... }:

{

  imports = [
    ../../modules/global.nix
  ];

  openssh.enable = true;
  docker.enable = true;
  grub.enable = true;
  keyMap.enable = true;
  i18n.enable = true;
  networkmanager.enable = true;
  experimental-features.enable = true;
  allowUnfree.enable = true;
  timeZone.enable = true;
  tailscale-server.enable = true;
  zsh.enable = true;



  environment.systemPackages =  with pkgs; [
    git
  ];

}
