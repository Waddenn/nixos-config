{ ... }: {
  imports = [ ../../modules/infra/proxmox-lxc.nix ];
  ansible.enable = true;
}
