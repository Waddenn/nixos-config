{ ... }: {
  imports = [ ../../modules/infra/proxmox-lxc.nix ];
  my-services.networking.ethtool.enable = true;
}
