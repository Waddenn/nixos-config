{ config, lib, ... }:

{
  options.timeZone.enable = lib.mkEnableOption "Enable timeZone";

  config = lib.mkIf config.timeZone.enable {

  time.timeZone = "Europe/Paris";

  };
}
