{ ... }: {
  imports = [ ../../modules/infra/proxmox-lxc.nix ];
  gatus.enable = true;
}
