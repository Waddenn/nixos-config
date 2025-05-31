{
  config,
  lib,
  ...
}: {
  options.gdm.enable = lib.mkEnableOption "Enable gdm";

  config = lib.mkIf config.gdm.enable {
    services.displayManager.gdm.enable = true;
  };
}
