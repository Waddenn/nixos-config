{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  immich.enable = true;
  networking.firewall.allowedTCPPorts = [2283];
}
