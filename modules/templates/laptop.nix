{ config, lib, pkgs, ... }:

{

  imports = [

    ../common/boot-loader/systemd-boot.nix
    ../common/console/keyMap.nix
    ../common/i18n/i18n.nix
    ../common/networking/firewall.nix
    ../common/networking/networkmanager.nix
    ../common/nix/gc.nix
    ../common/nix/settings.nix
    ../common/nixpkgs/config.nix
    ../common/programs/direnv.nix
    ../common/programs/firefox.nix
    ../common/programs/steam.nix
    ../common/security/rtkit.nix
    ../common/system/autoUpgrade.nix
    ../common/time/timeZone.nix
    ../common/zramSwap/zramswap.nix

    ../hardware/bluetooth.nix

    ../environment/gnome/excludePackages.nix
    ../environment/systemPackages/gnomeExtensions.nix

    ../services/flatpak.nix
    ../services/printing.nix
    ../services/pipewire.nix
    ../services/tailscale.nix
    ../services/fwupd.nix
    ../services/xserver-xkb.nix
    ../services/gnome.nix
    ../services/gdm.nix

  ];

}
