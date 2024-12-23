{ config, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common/steam.nix
    ../../modules/common/firefox.nix
    ../../modules/common/base.nix
    ../../modules/desktop/gnome/base.nix
    ../../modules/services/flatpak.nix
    ../../modules/services/printing.nix
    ../../modules/services/pipewire.nix
    ../../modules/services/tailscale.nix
    ../../modules/services/fwupd.nix
  ];

  networking.hostName = "asus-nixos";

  system.stateVersion = "25.05";

}
