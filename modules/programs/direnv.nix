{
  config,
  lib,
  ...
}: {
  options.my-services.programs.direnv.enable = lib.mkEnableOption "Enable direnv";

  config = lib.mkIf config.my-services.programs.direnv.enable {
    programs.direnv.enable = true;
  };
}
