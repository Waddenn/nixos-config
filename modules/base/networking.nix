{ config, pkgs, ... }:
{
  ###############################
  # Réseau
  ###############################
  networking = {
    hostName = "default-hostname";

    networkmanager.enable = true;
  };

}
