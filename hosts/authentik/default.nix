{ ... }: {
  imports = [ ../../modules/infra/proxmox-lxc.nix ];
  networking.firewall.allowedUDPPorts = [443 80];
}
