{ config, pkgs, ... }:

{

  imports = [

    # Bootloader
    ../../modules/boot/loader/systemd-boot.nix

    # Console settings
    ../../modules/console/keyMap.nix

    # Internationalization
    ../../modules/i18n/i18n.nix

    # Networking
    ../../modules/networking/firewall.nix
    ../../modules/networking/networkmanager.nix
    ../../modules/services/tailscale-client.nix

    # Nix settings
    ../../modules/nix/gc.nix
    ../../modules/nix/settings.nix
    ../../modules/nixpkgs/config.nix

    # Programs
    ../../modules/programs/direnv.nix
    ../../modules/programs/firefox.nix
    ../../modules/programs/steam.nix
    ../../modules/programs/zsh.nix

    # Security
    ../../modules/security/rtkit.nix

    # System configuration
    ../../modules/system/autoUpgrade.nix
    ../../modules/time/timeZone.nix
    ../../modules/zramSwap/zramswap.nix

    # Hardware
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/nvidia.nix

    # Environment
    ../../modules/environment/gnome/excludePackages.nix
    ../../modules/environment/systemPackages/gnomeExtensions.nix

    # Services
    ../../modules/services/flatpak.nix
    ../../modules/services/printing.nix
    ../../modules/services/pipewire.nix
    ../../modules/services/fwupd.nix
    ../../modules/services/xserver-xkb.nix
    ../../modules/services/gnome.nix
    ../../modules/services/gdm.nix

  ];

  environment.systemPackages = with pkgs; [
  ];

  services.flatpak.packages = [
    "tv.plex.PlexDesktop"
    "org.fedoraproject.MediaWriter"
  ];

}
