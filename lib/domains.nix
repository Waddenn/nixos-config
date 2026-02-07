# Centralized domain configuration
# This file defines all public domains managed by this infrastructure.
# Both Caddy (for reverse proxy) and Gatus (for monitoring) reference this.
{
  # List of all public domains with their backend services
  domains = {
    "nextcloud.hexaflare.net" = {
      backend = "http://192.168.40.116:80";
      monitoring = true;
    };
    "bitwarden.hexaflare.net" = {
      backend = "http://192.168.30.113:8222";
      monitoring = true;
    };
    "auth.hexaflare.net" = {
      backend = "http://192.168.40.107:80";
      monitoring = true;
    };
    "homeassistant.hexaflare.net" = {
      backend = "http://homeassistant:8123";
      monitoring = true;
    };
    "jellyseerr.hexaflare.net" = {
      backend = "http://192.168.40.121:5055";
      monitoring = true;
    };
    "immich.hexaflare.net" = {
      backend = "http://immich:2283";
      monitoring = true;
    };
  };
}
