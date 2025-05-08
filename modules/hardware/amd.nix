{
  config,
  lib,
  ...
}: {
  options.hardware.amd.enable = lib.mkEnableOption "Enable AMD hardware support";

  config = lib.mkIf config.hardware.amd.enable {
    hardware.cpu.amd.updateMicrocode = true;
  };
}
