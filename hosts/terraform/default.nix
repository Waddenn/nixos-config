{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  terraform.enable = true;
}
