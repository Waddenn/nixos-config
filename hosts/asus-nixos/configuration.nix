{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    
    ../../modules/base/localization.nix
    ../../modules/base/networking.nix
    ../../modules/base/system-configuration.nix
    ../../modules/base/zram.nix

    ../../modules/desktop/desktop-environments/gnome/gnome.nix

    ../../modules/desktop/default.nix
    ../../modules/desktop/gaming.nix

    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = lib.mkForce "asus-nixos";

  users.users.${username} = {
    isNormalUser = true;
    description  = "Tom";
    extraGroups  = [ "networkmanager" "wheel" "lp" "scanner" ];
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.${username} = import ./home.nix;

  services.flatpak.enable = true;
  services.fwupd.enable = true;

  programs.direnv.enable = true;

  system.stateVersion = "25.05";

}
