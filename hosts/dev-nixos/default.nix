{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  # No extra modules currently
  deployerNode.enable = true;
}
