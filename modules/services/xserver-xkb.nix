{
  config,
  lib,
  ...
}: {
  options.xkb.enable = lib.mkEnableOption "Enable xkb";

  config = lib.mkIf config.xkb.enable {
    services.xserver = {
      xkb = {
        layout = "fr";
        variant = "";
      };
    };
  };
}
