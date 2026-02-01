{
  config,
  lib,
  ...
}: {
  options = {
    immich.enable = lib.mkEnableOption "Enable immich";
  };

  config = lib.mkIf config.immich.enable {
    # Immich is only accessible via the Caddy reverse proxy on the internal network
    # This ensures all public traffic goes through HTTPS with security headers
    # Caddy connects via internal IP (192.168.40.115:2283)
    services.immich.enable = true;
    services.immich.port = 2283;
    services.immich.host = "0.0.0.0"; # Listen on internal network for Caddy reverse proxy
    # Note: Firewall configured in host to allow only internal network access
  };
}
