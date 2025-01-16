{ config, lib, ... }:

{
  options.fwupd.enable = lib.mkEnableOption "Enable fwupd";

  config = lib.mkIf config.fwupd.enable {

  services.fwupd.enable = true;

  };
}
