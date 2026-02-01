{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  my-services.misc.paperless.enable = true;
}
