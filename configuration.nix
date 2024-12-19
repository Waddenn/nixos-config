{ config, pkgs, inputs, ... }:

let
  frLocale = "fr_FR.UTF-8";
  enLocale = "en_US.UTF-8";
  keymap = "fr";
  userName = "tom";
  userGroups = [ "networkmanager" "wheel" "lp" "scanner" ];

  gnomeExtensions = with pkgs.gnomeExtensions; [
    hide-top-bar
    tailscale-qs
    appindicator
    alphabetical-app-grid
    search-light
    battery-health-charging
    system-monitor
    bluetooth-battery-meter
    blur-my-shell
  ];

  systemPackages = with pkgs; [
  ];

  unneededGnomePackages = with pkgs; [
    gnome-tour
    epiphany
    geary
    evince
    totem
    gnome-connections
    gnome-music
    gnome-shell-extensions
  ];
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 20;
      consoleMode = "auto";
    };
    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "asus-nixos";
    networkmanager.enable = true;
    firewall.enable = true;
  };

  time.timeZone = "Europe/Paris";

  i18n = {
    defaultLocale = enLocale;
    extraLocaleSettings = {
      LC_ADDRESS = frLocale;
      LC_IDENTIFICATION = frLocale;
      LC_MEASUREMENT = frLocale;
      LC_MONETARY = frLocale;
      LC_NAME = frLocale;
      LC_NUMERIC = frLocale;
      LC_PAPER = frLocale;
      LC_TELEPHONE = frLocale;
      LC_TIME = frLocale;
    };
  };

  console.keyMap = keymap;

  services = {
    xserver = {
      enable = true;

      xkb = {
        layout = "fr"; 
        variant = "";  
      };

      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    printing.enable = true;

    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true; 
      };
      pulse.enable = true;
    };

    flatpak.enable = true;
    fwupd.enable = true;

    tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "client";
    };
  };

  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = true;
  security.rtkit.enable = true;
  programs.direnv.enable = true;
  zramSwap.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users.${userName} = {
    isNormalUser = true;
    description = "Tom";
    extraGroups = userGroups;
    packages = [];
  };

  environment = {
    systemPackages = systemPackages  ++ gnomeExtensions;
    gnome.excludePackages = unneededGnomePackages;
  };

  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };
  };

  nixpkgs.config.allowUnfree = true;

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      persistent = true;
      options = "--delete-older-than 14d";
    };
  };

  system = {
    autoUpgrade = {
      enable = true;
      allowReboot = false;
      dates = "daily";
      persistent = true;
    };
    stateVersion = "24.05";
  };
}
