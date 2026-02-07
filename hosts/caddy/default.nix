{lib, ...}: {
  profiles.lxc-base.enable = true;
  my-services.networking.caddy.enable = true;
}
