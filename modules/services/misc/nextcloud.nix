# openssl rand -base64 32 | sudo tee /var/lib/nextcloud/admin-pass > /dev/null
# sudo chmod 600 /var/lib/nextcloud/admin-pass
# sudo chown nextcloud:nextcloud /var/lib/nextcloud/admin-pass
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.my-services.misc.nextcloud.enable = lib.mkEnableOption "Enable nextcloud";

  config = lib.mkIf config.my-services.misc.nextcloud.enable {
    services.nextcloud = {
      enable = true;
      # Major upgrades must remain sequential. Keep this on 33 until the
      # application and database checks in docs/operations.md have passed.
      package = pkgs.nextcloud33;
      hostName = "nextcloud.hexaflare.net";
      database.createLocally = true;
      configureRedis = true;
      config = {
        dbtype = "pgsql";
        adminpassFile = "/var/lib/nextcloud/admin-pass";
      };

      settings = {
        log_type = "file";
        default_phone_region = "FR";
        maintenance_window_start = 1;
        overwriteprotocol = "https";
        trusted_proxies = ["192.168.40.105"];
        trusted_domains = [
          "nextcloud.hexaflare.net"
          "192.168.40.116"
        ];
      };

      phpOptions = {
        "opcache.interned_strings_buffer" = "16";
        "memory_limit" = "512M";
      };

      # Conservative starting limits for 6 GiB shared with PostgreSQL; tune from measured RSS.
      poolSettings = {
        "pm" = "dynamic";
        "pm.max_children" = "8"; # Maximum concurrent workers
        "pm.start_servers" = "3"; # Initial workers on startup
        "pm.min_spare_servers" = "2"; # Minimum idle workers
        "pm.max_spare_servers" = "4"; # Maximum idle workers
        "pm.max_requests" = "500"; # Recycle workers to prevent memory leaks
      };

      appstoreEnable = true;

      extraAppsEnable = true;
      extraApps = with config.services.nextcloud.package.packages.apps; {
        inherit
          calendar
          contacts
          notes
          onlyoffice
          tasks
          ;
      };
    };

    # PostgreSQL performance tuning for 6GB RAM
    services.postgresql = {
      settings = {
        max_connections = 50; # Accommodate all PHP-FPM workers + overhead
        shared_buffers = "512MB"; # Shared buffers
        effective_cache_size = "3GB"; # ~50% of RAM for query planning
        work_mem = "8MB"; # Per-operation memory
        maintenance_work_mem = "128MB"; # Maintenance operations (VACUUM, CREATE INDEX)
        checkpoint_completion_target = "0.9"; # Spread checkpoints
        wal_buffers = "16MB"; # Write-ahead log buffer
        random_page_cost = "1.1"; # SSD optimization
        effective_io_concurrency = 200; # SSD concurrent I/O
      };
    };

    # Keep a logical dump available before application upgrades. The migration
    # runbook still requires a fresh, explicitly verified dump and datadir copy.
    services.postgresqlBackup = {
      enable = true;
      backupAll = false;
      databases = ["nextcloud"];
      location = "/var/backup/postgresql";
      startAt = "01:15";
    };

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
