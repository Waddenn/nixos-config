{ config, pkgs, ... }:

{
  
  services.xserver = {

    xkb = {
      layout = "fr";
      variant = "";
    };
  };

}
