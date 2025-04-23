{
  config,
  lib,
  ...
}: {
  options.grub.enable = lib.mkEnableOption "Enable grub";

  config = lib.mkIf config.grub.enable {
    boot.loader.grub.enable = true;
    boot.loader.grub.devices = ["/dev/sda"];
  };
}
