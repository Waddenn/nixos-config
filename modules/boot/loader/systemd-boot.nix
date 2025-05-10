{
  config,
  lib,
  ...
}: {
  options.systemd-boot.enable = lib.mkEnableOption "Enable systemd-boot";

  config = lib.mkIf config.systemd-boot.enable {
    boot.loader.systemd-boot = {
      enable = true;
      configurationLimit = 20;
    };

    boot.loader.efi.canTouchEfiVariables = true;

    boot.kernelParams = [
      "quiet"
      "splash"
      "vga=current"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];

    boot.consoleLogLevel = 0;
    boot.initrd.verbose = false;
  };
}
