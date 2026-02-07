{...}: {
  profiles.lxc-base.enable = true;
  prometheus.enableServer = true;
  prometheus.enableClient = true;
  loki.enable = true;
  promtail.enable = true;
}
