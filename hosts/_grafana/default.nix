{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  my-services.monitoring.grafana.enable = true;
  prometheus.enableServer = true;
  prometheus.enableClient = true;
}
