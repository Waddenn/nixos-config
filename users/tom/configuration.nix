{ config, lib, pkgs, inputs, username, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ../../modules/services/tailscale.nix
    ../../modules/services/flatpak.nix
  ];

  users.users.${username} = {
    isNormalUser = true;
    description  = "Tom";
    extraGroups  = [ "networkmanager" "wheel" "lp" "scanner" ];
  };

}
