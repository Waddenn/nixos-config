{ config, lib, ... }:

{
  options.gnome.enable = lib.mkEnableOption "Enable gnome";

  config = lib.mkIf config.gnome.enable {

  services.xserver = {
    enable = true;

    desktopManager.gnome.enable = true;

  };

  };
}
