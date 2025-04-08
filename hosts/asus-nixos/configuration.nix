
{ config, pkgs, inputs, sops-nix, ... }:

{
  
  imports = [
    ../../modules/global.nix
  ];
  
  # environment.systemPackages = with pkgs; [
  #   age
  #   sops
  #   just
  #   mesa
  # ];

  # services.flatpak.packages = [
  #   "tv.plex.PlexDesktop"
  #   "org.fedoraproject.MediaWriter"
  #   "dev.vencord.Vesktop"
  #   "com.github.taiko2k.avvie"
  #   "com.boxy_svg.BoxySVG"
  # ];

  # autoUpgrade.enable = true;
  # firefox.enable = true;
  # bluetooth.enable = true;
  # systemd-boot.enable = true;
  # keyMap.enable = true;
  # i18n.enable = true;
  # networkmanager.enable = true;
  # tailscale-client.enable = true;
  # gc.enable = true;
  # experimental-features.enable = true;
  # allowUnfree.enable = true;
  # direnv.enable = true;
  # steam.enable = true;
  # zsh.enable = true;
  # rtkit.enable = true;
  # timeZone.enable = true;
  # zram.enable = true;
  # gnome-excludePackages.enable = true;
  # gnomeExtensions.enable = true;
  # flatpak.enable = true;
  # printing.enable = true;
  # pipewire.enable = true;
  # fprintd.enable = false;
  # fwupd.enable = true;
  # xkb.enable = true;
  # gnome.enable = true;
  # gdm.enable = true;
  # docker.enable = true;
  # hyprland.enable = true;

  # linuxPackages.enable6_6 = true;

    hydenix = {

    #! Important options
    enable = true; # enable hydenix - required, default false
    hostname = "hydenix"; # hostname
    timezone = "Europe/Paris"; # timezone
    locale = "en_US.UTF-8"; # locale

    #! Below are defaults
    audio.enable = true; # enable audio module
    boot = {
      enable = true; # enable boot module
      useSystemdBoot = true; # disable for GRUB
      grubTheme = pkgs.hydenix.grub-retroboot; # or pkgs.hydenix.grub-pochita
      grubExtraConfig = ""; # additional GRUB configuration
      kernelPackages = pkgs.linuxPackages_zen; # default zen kernel
    };
    gaming.enable = true; # enable gaming module
    hardware.enable = true; # enable hardware module
    network.enable = true; # enable network module
    nix.enable = true; # enable nix module
    sddm = {
      enable = true; # enable sddm module
      theme = pkgs.hydenix.sddm-candy; # or pkgs.hydenix.sddm-corners
    };
    system.enable = true; # enable system module
  };
} 
