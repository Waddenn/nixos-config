{ ... }: {
  imports = [ ../../modules/infra/proxmox-lxc.nix ];
  adguardhome.enable = true;
}
