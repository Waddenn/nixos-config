{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  # No extra modules currently
  my-services.infra.deployer-node.enable = true;
}
