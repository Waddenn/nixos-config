{ config, lib, pkgs, ... }:

{

  imports = [

    ../common/steam.nix
    ../common/firefox.nix
    ../common/base.nix
    ../common/direnv.nix
    ../common/systemd-boot.nix
    ../common/zramswap.nix
    ../common/direnv.nix
    ../common/firewall.nix
    ../common/garbage-collection.nix
    ../common/locale.nix
    ../common/system-autoupgrade.nix

    ../desktop/gnome/base.nix

    ../services/flatpak.nix
    ../services/printing.nix
    ../services/pipewire.nix
    ../services/tailscale.nix
    ../services/fwupd.nix

  ];

}
