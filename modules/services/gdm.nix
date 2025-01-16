{ config, lib, ... }:

{
  options.gdm.enable = lib.mkEnableOption "Enable gdm";

  config = lib.mkIf config.gdm.enable {

  services.xserver = {
    enable = true;

    displayManager.gdm.enable = true;

  };
  
  };
}
