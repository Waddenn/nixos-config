{ ... }: {
  imports = [ ../../modules/infra/proxmox-lxc.nix ];
  jellyseerr.enable = true;
}
