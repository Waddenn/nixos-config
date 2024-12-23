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

  zramSwap.enable = true;
  networkmanager.enable = true;

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  console.keyMap = "fr";
}
