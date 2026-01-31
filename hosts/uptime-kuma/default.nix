{ ... }: {
  imports = [ ../../modules/infra/proxmox-lxc.nix ];
  my-services.uptime-kuma.enable = true;
}
