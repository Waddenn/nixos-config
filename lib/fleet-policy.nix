# Deployment policy only; service settings remain in their host modules.
{
  authelia = {
    canary = true;
    units = ["authelia.service" "redis-authelia.service"];
    urls = ["http://127.0.0.1:9091/api/health"];
  };
  caddy = {
    canary = true;
    units = ["caddy.service"];
    urls = ["https://auth.hexaflare.net/api/health"];
  };
  adguardhome.units = ["adguardhome.service"];
  beszel.units = ["docker-beszel.service"];
  calibre.units = ["docker-calibre.service"];
  gatus.units = ["gatus.service"];
  glance.units = ["glance.service"];
  gotify.units = ["gotify-server.service"];
  immich.units = ["immich-server.service" "postgresql.service"];
  jellyseerr.units = ["seerr.service"];
  nextcloud-pgsql = {
    units = ["phpfpm-nextcloud.service" "postgresql.service" "nginx.service"];
    urls = ["http://192.168.40.116/status.php"];
  };
  paperless.units = ["paperless-web.service"];
  valheim.units = ["docker-valheim.service"];
  vaultwarden.units = ["vaultwarden.service"];
}
