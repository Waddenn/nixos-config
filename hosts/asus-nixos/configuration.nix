{ config, lib, pkgs, inputs, username, ... }:

{
  imports = [
    ./hardware-configuration.nix
    
    ../../modules/common/system-configuration.nix

    ../../modules/desktop/gnome/base.nix

    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "asus-nixos";

  services.fwupd.enable = true;

  programs.direnv.enable = true;

  system.stateVersion = "25.05";

  hardware.bluetooth.enable = true;
  security.rtkit.enable = true;

}
