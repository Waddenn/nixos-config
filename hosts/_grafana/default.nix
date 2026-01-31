{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  grafana.enable = true;
  prometheus.enableServer = true;
  prometheus.enableClient = true;
}
