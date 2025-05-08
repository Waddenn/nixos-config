{
  config,
  lib,
  ...
}: {
  options.blueman.enable = lib.mkEnableOption "Enable blueman";

  config = lib.mkIf config.blueman.enable {
    services.blueman.enable = true;
  };
}
