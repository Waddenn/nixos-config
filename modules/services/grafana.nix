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
    };

    networking.firewall.allowedTCPPorts = [3000];
  };
}
