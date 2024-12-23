{ config, lib, pkgs, inputs, username, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  users.users.${username} = {
    isNormalUser = true;
    description  = "Tom";
    extraGroups  = [ "networkmanager" "wheel" "lp" "scanner" ];
  };

}
