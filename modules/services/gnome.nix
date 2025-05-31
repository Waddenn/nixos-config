{
  config,
  lib,
  ...
}: {
  options.gnome.enable = lib.mkEnableOption "Enable gnome";

  config = lib.mkIf config.gnome.enable {
    services.desktopManager.gnome.enable = true;
  };
}
