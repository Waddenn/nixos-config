{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  networking.firewall.allowedTCPPorts = [5000];
}
