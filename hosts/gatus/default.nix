{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  my-services.monitoring.gatus.enable = true;
}
