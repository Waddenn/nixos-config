{ config, lib, pkgs, ... }:

{

  users.users.tom = {
    isNormalUser = true;
    description  = "Nixos";
    extraGroups  = [ "networkmanager" "wheel" ];
  };

}
