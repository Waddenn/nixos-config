{
  config,
  lib,
  pkgs,
  ...
}: {
  options.my-services.media.jellyseerr.enable = lib.mkEnableOption "Enable Jellyseerr service";

  config = lib.mkIf config.my-services.media.jellyseerr.enable {
    services.jellyseerr = {
      enable = true;
      port = 5055;
      openFirewall = true;
      package = pkgs.jellyseerr;
    };
  };
}
