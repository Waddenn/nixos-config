{ config, ... }:

{

  imports = [

    ../boot/loader/systemd-boot.nix
    ../boot/kernel.nix
    ../console/keyMap.nix
    ../i18n/i18n.nix
    ../networking/firewall.nix
    ../networking/networkmanager.nix
    ../nix/gc.nix
    ../nix/settings.nix
    ../nixpkgs/config.nix
    ../programs/direnv.nix
    ../programs/firefox.nix
    ../programs/steam.nix
    ../security/rtkit.nix
    ../system/autoUpgrade.nix
    ../time/timeZone.nix
    ../zramSwap/zramswap.nix

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
