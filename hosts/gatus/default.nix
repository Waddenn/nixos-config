{...}: {
  my-services.networking.tailscale.tags = ["tag:managed-server" "tag:gatus"];
  profiles.lxc-base.enable = true;
  my-services.monitoring.gatus.enable = true;
}
