{
  config,
  lib,
  ...
}: {
  options.upower.enable = lib.mkEnableOption "Enable upower";

  config = lib.mkIf config.upower.enable {
    services.upower.enable = true;
  };
}
