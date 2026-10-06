{lib, ...}: {
  my-services.networking.tailscale.tags = ["tag:managed-server" "tag:caddy"];
  profiles.lxc-base.enable = true;
  my-services.networking.caddy.enable = true;
}
