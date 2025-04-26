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
          # 1. Scrape du journal systemd
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
            ];
          }

          # 2. Scrape de tous les fichiers dans /var/log
          {
            job_name = "varlogs";
            static_configs = [
              {
                targets = [];
                labels = {
                  job = "varlogs";
                  __path__ = "/var/log/**/*.log"; # tous les .log classiques
                };
              }
            ];
          }

          # 3. Scrape de messages génériques comme syslog, messages, dmesg
          {
            job_name = "text-logs";
            static_configs = [
              {
                targets = [];
                labels = {
                  job = "text-logs";
                  __path__ = "/var/log/{syslog,messages,dmesg}"; # fichiers clés
                };
              }
            ];
          }
        ];
      };
    };
    networking.firewall.allowedTCPPorts = [3031];
  };
}
