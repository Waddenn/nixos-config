{ ... }: {
  imports = [ ../../modules/infra/proxmox-lxc.nix ];
  glance.enable = true;
}
