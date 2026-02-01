{
  config,
  lib,
  ...
}: {
  options = {
    immich.enable = lib.mkEnableOption "Enable immich";
  };

  config = lib.mkIf config.immich.enable {
    services.immich.enable = true;
    services.immich.port = 2283;
    services.immich.host = "0.0.0.0"; # Allow access from Caddy proxy
    services.immich.openFirewall = true;
  };
}
