{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  gitlab.enable = true;
}
# Triggering re-deployment after emergency cleanup
