{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.prometheus;
in {
  options = {
    prometheus = {
      enableServer = lib.mkEnableOption "Enable Prometheus server";
      enableClient = lib.mkEnableOption "Enable Prometheus node_exporter";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enableServer {
      services.prometheus = {
        enable = true;
        globalConfig.scrape_interval = "10s";
        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [
              {
                targets = ["caddy:9000"];
              }
            ];
          }
          {
            job_name = "caddy";
            static_configs = [
              {
                targets = ["caddy:2019"];
              }
            ];
          }
        ];
      };
      networking.firewall.allowedTCPPorts = [9090];
    })

    (lib.mkIf cfg.enableClient {
      services.prometheus.exporters.node = {
        enable = true;
        port = 9000;
        enabledCollectors = ["systemd"];
        extraFlags = ["--collector.ethtool" "--collector.softirqs" "--collector.tcpstat" "--collector.wifi"];
      };
      networking.firewall.allowedTCPPorts = [9000];
    })
  ];
}
