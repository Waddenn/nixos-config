{ config, pkgs, ... }:
{
  
  networking = {
    hostName = "default-hostname";

    networkmanager.enable = true;
  };

}
