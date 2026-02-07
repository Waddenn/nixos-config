{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  my-services.monitoring.gatus.enable = true;
  my-services.infra.deployment-target.enable = true;
  my-services.infra.pull-updater.canary = true;
}
