{
  config,
  lib,
  ...
}: {
  options.bluetooth.enable = lib.mkEnableOption "Enable Bluetooth";

  config = lib.mkIf config.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;

      settings = {
        General = {
          Discoverable = false;
          DiscoverableTimeout = 0;
        };
      };
    };
  };
}
