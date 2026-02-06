{lib, ...}: {
  profiles.lxc-base.enable = true;
  my-services.networking.caddy.enable = true;
  my-services.infra.deployment-target.enable = true;
  my-services.infra.pull-updater.canary = true;
}
