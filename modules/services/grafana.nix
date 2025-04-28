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
          ];
        };
      };
    };

    networking.firewall.allowedTCPPorts = [3000];
  };
}
