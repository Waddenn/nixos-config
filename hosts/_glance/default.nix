{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  my-services.monitoring.glance.enable = true;
}
