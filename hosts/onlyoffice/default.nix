{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  my-services.misc.onlyoffice.enable = true;
}
