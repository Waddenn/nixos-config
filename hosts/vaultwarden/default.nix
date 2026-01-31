{ ... }: {
  imports = [ ../../modules/infra/proxmox-lxc.nix ];
  vaultwarden.enable = true;
}
