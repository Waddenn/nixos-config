{
  config,
  lib,
  pkgs,
  ...
}: {
  options.printing.enable = lib.mkEnableOption "Enable printing";

  config = lib.mkIf config.printing.enable {
    services.printing.enable = true;
    services.printing.drivers = [pkgs.hplip];
  };
}
