{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    (lib.mkRenamedOptionModule
      ["my-services" "media" "jellyseerr" "enable"]
      ["my-services" "media" "seerr" "enable"])
  ];

  options.my-services.media.seerr.enable = lib.mkEnableOption "Enable Seerr service";

  config = lib.mkIf config.my-services.media.seerr.enable {
    services.seerr = {
      enable = true;
      port = 5055;
      openFirewall = true;
      package = pkgs.seerr;
    };
  };
}
