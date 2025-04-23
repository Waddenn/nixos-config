{
  config,
  lib,
  ...
}: {
  options.networkmanager.enable = lib.mkEnableOption "Enable networkmanager";

  config = lib.mkIf config.networkmanager.enable {
    networking.networkmanager.enable = true;
  };
}
