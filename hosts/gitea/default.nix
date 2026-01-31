{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  gitea.enable = true;
}
