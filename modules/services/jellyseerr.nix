{
  config,
  lib,
  pkgs,
  ...
}: {
  options.jellyseerr.enable = lib.mkEnableOption "Enable Jellyseerr service";

  config = lib.mkIf config.jellyseerr.enable {
    services.jellyseerr = {
      enable = true;
      port = 5055;
      openFirewall = true;
      package = pkgs.jellyseerr;
    };
  };
}
