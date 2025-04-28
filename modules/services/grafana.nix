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
              url = "http://localhost:9090";
              isDefault = true;
            }
          ];
        };

        dashboards.settings = {
          apiVersion = 1;
          providers = [
            {
              name = "node-exporter-dashboards";
              options.path = "/etc/grafana/dashboards";
            }
          ];
        };
      };
    };

    environment.etc."grafana/dashboards/Node Exporter Full.json".source =
      /home/nixos/nixos-config/modules/services/grafana/Node-Exporter-Full.json;

    networking.firewall.allowedTCPPorts = [3000];
  };
}
