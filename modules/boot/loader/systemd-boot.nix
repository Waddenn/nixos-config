{
  config,
  lib,
  ...
}: {
  options.systemd-boot.enable = lib.mkEnableOption "Enable systemd-boot";

  config = lib.mkIf config.systemd-boot.enable {
    boot = {
      bootspec.enable = true;
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot = {
          enable = true;
          consoleMode = "auto";
          configurationLimit = 8;
        };
      };
      tmp.cleanOnBoot = true;

      kernelParams = [
        "quiet"
        "splash"
        "vga=current"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
      ];

      consoleLogLevel = 0;
      initrd.verbose = false;
    };
  };
}
