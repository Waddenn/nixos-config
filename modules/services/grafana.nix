{
  config,
  lib,
  ...
}: {
  options = {
    grafana.enable = lib.mkEnableOption "Enable grafana";
  };

  config = lib.mkIf config.grafana.enable {
    services.grafana = {
      enable = true;

      settings = {
        server.http_addr = "0.0.0.0";
        server.http_port = 3000;
      };

      provision = {
        enable = true;

        datasources.settings = {
          apiVersion = 1;
          datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              access = "proxy";
              url = "http://192.168.1.117:9090";
              isDefault = true;
            }
            {
              name = "Loki";
              type = "loki";
              access = "proxy";
              url = "http://192.168.1.117:3030";
              isDefault = false;
            }
          ];
        };

        dashboards.settings = {
          apiVersion = 1;
          providers = [
            {
              name = "default-dashboards";
              options.path = "/etc/grafana/dashboards";
            }
          ];
        };
      };
    };

    environment.etc."grafana/dashboards/Node-Exporter-Full.json".source =
      /home/nixos/nixos-config/modules/services/grafana/Node-Exporter-Full.json;

    environment.etc."grafana/dashboards/Simple-System-Logs-Loki.json".source =
      /home/nixos/nixos-config/modules/services/grafana/Simple-System-Logs-Loki.json;

    networking.firewall.allowedTCPPorts = [3000];
  };
}
