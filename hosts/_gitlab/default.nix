{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  my-services.dev.gitlab.enable = true;
}
# Triggering re-deployment after emergency cleanup
