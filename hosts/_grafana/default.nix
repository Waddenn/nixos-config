{...}: {
  profiles.lxc-base.enable = true;
  my-services.monitoring.grafana.enable = true;
  prometheus.enableServer = true;
  prometheus.enableClient = true;
}
