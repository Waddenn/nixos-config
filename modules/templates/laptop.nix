{ config, lib, pkgs, hostname, ... }:

{

  imports = [
    ../../../modules/common/steam.nix
    ../../../modules/common/firefox.nix
    ../../../modules/common/base.nix
    ../../../modules/common/direnv.nix
    ../../../modules/common/systemd-boot.nix
    ../../../modules/common/zramswap.nix
    ../../../modules/desktop/gnome/base.nix
    ../../../modules/services/flatpak.nix
    ../../../modules/services/printing.nix
    ../../../modules/services/pipewire.nix
    ../../../modules/services/tailscale.nix
    ../../../modules/services/fwupd.nix
  ];

}
