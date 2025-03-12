
{ config, pkgs, ... }:

{

  imports = [
    ../../modules/global.nix
  ];

  openssh.enable = true;
  docker.enable = true;
  boot.loader.grub.enable = true;
  console.keyMap.enable = true;
  i18n.enable = true;
  networking.networkmanager.enable = true;
  nix.settings.enable = true;
  nixpkgs.config.enable = true;
  time.timeZone.enable = true;
  programs.zsh.enable = true;


  environment.systemPackages =  with pkgs; [
    git
  ];

}
