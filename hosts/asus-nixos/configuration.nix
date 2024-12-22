{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    
    ../../modules/base/localization.nix
    ../../modules/base/networking.nix
    ../../modules/base/system-configuration.nix
    ../../modules/base/zram.nix

    ../../modules/desktop/desktop-environments/gnome.nix

    ../../modules/desktop/bluetooth.nix
    ../../modules/desktop/gaming.nix
    ../../modules/desktop/pipewire.nix
    ../../modules/desktop/printing.nix

    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = lib.mkForce "asus-nixos";

  users.users.tom = {
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
  home-manager.users.tom = import ./home.nix;

  services.flatpak.enable = true;
  services.fwupd.enable = true;

  programs.direnv.enable = true;

  system.stateVersion = "25.05";

}
