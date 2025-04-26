{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.loki;
in {
  options = {
    loki = {
      enable = lib.mkEnableOption "Enable Loki server";
    };
  };

  config = lib.mkIf cfg.enable {
    services.loki = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 3030;
        };
        auth_enabled = false;

        common = {
          path_prefix = "/var/lib/loki"; # << obligatoire pour path
        };

        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore.store = "inmemory";
              replication_factor = 1;
            };
          };
          chunk_idle_period = "1h";
          max_chunk_age = "1h";
        };

        schema_config = {
          configs = [
            {
              from = "2024-01-01";
              store = "tsdb"; # << index backend
              object_store = "filesystem"; # << chunks backend
              schema = "v13"; # << storage schema
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };

        storage_config = {
          filesystem = {
            directory = "/var/lib/loki/chunks"; # <- chunks path
          };
          tsdb_shipper = {
            active_index_directory = "/var/lib/loki/tsdb-index"; # <- TSDB index
          };
        };

        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
          # plus besoin de allow_structured_metadata: false avec v13
        };

        compactor = {
          working_directory = "/var/lib/loki/compactor"; # <- obligatoire
        };
      };
    };
    networking.firewall.allowedTCPPorts = [3030];
  };
}
