{ config, pkgs, ... }:

{

  hardware.bluetooth.enable = true;

  hardware.bluetooth.settings = {
  General = {
    Discoverable = false;       
    DiscoverableTimeout = 0;   
  };
};


}
