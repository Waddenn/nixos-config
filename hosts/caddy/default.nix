{lib, ...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  caddy.enable = true;
}
