{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  my-services.media.jellyseerr.enable = true;
  my-services.infra.deployment-target.enable = true;
}
