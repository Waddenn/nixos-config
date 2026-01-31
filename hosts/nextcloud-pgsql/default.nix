{ ... }: {
  imports = [ ../../modules/infra/proxmox-lxc.nix ];
  nextcloud.enable = true;
}
