{
  config,
  lib,
  ...
}: {
  options = {
    immich.enable = lib.mkEnableOption "Enable immich";
  };

  config = lib.mkIf config.immich.enable {
    # Immich is only accessible via the Caddy reverse proxy
    # This ensures all traffic goes through HTTPS with security headers
    services.immich.enable = true;
    services.immich.port = 2283;
    services.immich.host = "127.0.0.1"; # Only accessible via localhost reverse proxy
    # openFirewall not needed: Immich is accessed via Caddy (port 443) only
  };
}
