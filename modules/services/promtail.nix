{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.promtail;
in {
  options = {
    promtail = {
      enable = lib.mkEnableOption "Enable Promtail agent";
    };
  };

  config = lib.mkIf cfg.enable {
    services.promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 3031;
          grpc_listen_port = 0;
        };

        positions.filename = "/tmp/positions.yaml";

        clients = [
          {
            url = "http://127.0.0.1:3030/loki/api/v1/push";
          }
        ];

        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = "localhost";
              };
            };
            relabel_configs = [
              {
                source_labels = ["__journal__systemd_unit"];
                target_label = "unit";
              }
              {
                source_labels = ["__journal_syslog_identifier"];
                target_label = "service_name";
              }
            ];
          }
        ];
      };
    };
    networking.firewall.allowedTCPPorts = [3031];
  };
}
