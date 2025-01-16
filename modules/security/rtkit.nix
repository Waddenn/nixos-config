{ config, lib, ... }:

{
  options.rtkit.enable = lib.mkEnableOption "Enable rtkit";

  config = lib.mkIf config.rtkit.enable {

  security.rtkit.enable = true;

  };
}
