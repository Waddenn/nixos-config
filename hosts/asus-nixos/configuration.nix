{ config, lib, pkgs, inputs, username, ... }:

{
  imports = [
    ./hardware-configuration.nix
    
    ../../modules/common/localization.nix
    ../../modules/common/networking.nix
    ../../modules/common/system-configuration.nix
    ../../modules/common/zram.nix

    ../../modules/desktop/desktop-environments/gnome/gnome.nix

    ../../modules/desktop/default.nix
    ../../modules/desktop/gaming.nix

    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = lib.mkForce "asus-nixos";

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
  };

  services.flatpak.enable = true;
  services.fwupd.enable = true;

  programs.direnv.enable = true;

  system.stateVersion = "25.05";

}
