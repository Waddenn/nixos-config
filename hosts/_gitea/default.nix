{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  my-services.dev.gitea.enable = true;
}
