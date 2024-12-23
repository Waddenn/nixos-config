{ config, lib, pkgs, username, ... }:

{
  imports = [
    ../../modules/common/gaming.nix
    ../../modules/services/flatpak.nix
    ../../modules/services/printing.nix
    ../../modules/services/pipewire.nix
    ../../modules/services/tailscale.nix
  ];

  users.users.${username} = {
    isNormalUser = true;
    description  = "Tom";
    extraGroups  = [ "networkmanager" "wheel" "lp" "scanner" ];
  };

}
