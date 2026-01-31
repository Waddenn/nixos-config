{ ... }: {
  imports = [ ../../modules/infra/proxmox-lxc.nix ];
  ethtool.enable = true;
}
