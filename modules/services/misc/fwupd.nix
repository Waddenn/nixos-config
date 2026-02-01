{
  config,
  lib,
  ...
}: {
  options.my-services.misc.fwupd.enable = lib.mkEnableOption "Enable fwupd";

  config = lib.mkIf config.my-services.misc.fwupd.enable {
    services.fwupd.enable = true;
  };
}
