{ config, lib, ... }:

{
  options = {
    immich.enable = lib.mkEnableOption "Enable immich";
  };

  config = lib.mkIf config.immich.enable {
    services.immich.enable = true;
    services.immich.port = 2283;
  };
}