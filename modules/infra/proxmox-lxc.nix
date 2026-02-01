{...}: {
  imports = [./proxmox-lxc-config.nix];
  my-services.infra.proxmox-lxc.enable = true;
}
