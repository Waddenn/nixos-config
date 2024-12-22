{ config, pkgs, ... }:
{
  ###############################
  # Boot loader, EFI, etc.
  ###############################
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    systemd-boot.configurationLimit = 20;
  };

  ###############################
  # Firewall
  ###############################
  networking.firewall.enable = true;

  ###############################
  # Options Nix
  ###############################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  ###############################
  # Garbage collection
  ###############################
  nix.gc = {
    automatic = true;
    dates = "weekly";
    persistent = true;
    options = "--delete-older-than 14d";
  };

  ###############################
  # Mises à jour automatiques
  ###############################
  system.autoUpgrade = {
    enable = true;
    dates = "daily";
    persistent = true;
    flags = [ "--update-input" "nixpkgs" ];
  };



}
