{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my-services.auth.authelia;

  # Configuration Authelia
  autheliaConfig = {
    theme = "auto";

    server = {
      address = "tcp://${cfg.host}:${toString cfg.port}";
      endpoints = {
        authz = {
          forward-auth = {
            implementation = "ForwardAuth";
            authn_strategies = [
              {
                name = "HeaderProxyAuthorization";
                schemes = ["Bearer"];
              }
              {name = "CookieSession";}
            ];
          };
        };
      };
    };

    log = {
      level = cfg.logLevel;
      format = "text";
    };

    telemetry.metrics = {
      enabled = true;
      address = "tcp://${cfg.host}:${toString cfg.metricsPort}";
    };

    authentication_backend = {
      password_reset.disable = false;
      file = {
        path = cfg.usersFile;
        watch = true;
        password = {
          algorithm = "argon2";
          argon2 = {
            variant = "argon2id";
            iterations = 3;
            memory = 65536;
            parallelism = 4;
            key_length = 32;
            salt_length = 16;
          };
        };
      };
    };

    session = {
      name = "authelia_session";
      domain = cfg.domain;
      expiration = "1h";
      inactivity = "5m";
      remember_me = "1M";

      redis = {
        host = cfg.redis.host;
        port = cfg.redis.port;
        database_index = cfg.redis.databaseIndex;
      };
    };

    storage = {
      encryption_key = {_secret = "/run/secrets/authelia_storage_encryption_key";};

      postgres = lib.mkIf (cfg.database.type == "postgres") {
        address = "tcp://${cfg.database.host}:${toString cfg.database.port}";
        database = cfg.database.name;
        username = cfg.database.user;
        password = {_secret = "/run/secrets/authelia_db_password";};
      };

      local = lib.mkIf (cfg.database.type == "sqlite") {
        path = "${cfg.dataDir}/db.sqlite3";
      };
    };

    notifier = {
      disable_startup_check = true;
      filesystem = {
        filename = "${cfg.dataDir}/notification.txt";
      };
    };

    access_control = {
      default_policy = cfg.defaultPolicy;

      rules = cfg.accessControlRules;
    };

    identity_validation.reset_password.jwt_secret = {_secret = "/run/secrets/authelia_jwt_secret";};
  };

  configFormat = pkgs.formats.yaml {};
  configFile = configFormat.generate "authelia-config.yml" autheliaConfig;
in {
  options.my-services.auth.authelia = {
    enable = lib.mkEnableOption "Enable Authelia";

    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Address to bind Authelia to";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9091;
      description = "Port for Authelia service";
    };

    metricsPort = lib.mkOption {
      type = lib.types.port;
      default = 9959;
      description = "Port for Prometheus metrics";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      example = "hexaflare.net";
      description = "Root domain for session cookies";
    };

    logLevel = lib.mkOption {
      type = lib.types.enum ["trace" "debug" "info" "warn" "error"];
      default = "info";
      description = "Log level for Authelia";
    };

    defaultPolicy = lib.mkOption {
      type = lib.types.enum ["deny" "bypass" "one_factor" "two_factor"];
      default = "deny";
      description = "Default access control policy";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/authelia";
      description = "Directory for Authelia data";
    };

    usersFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/authelia/users_database.yml";
      description = "Path to users database file";
    };

    database = {
      type = lib.mkOption {
        type = lib.types.enum ["sqlite" "postgres"];
        default = "sqlite";
        description = "Database type to use";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "localhost";
        description = "Database host (for PostgreSQL)";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 5432;
        description = "Database port (for PostgreSQL)";
      };

      name = lib.mkOption {
        type = lib.types.str;
        default = "authelia";
        description = "Database name";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "authelia";
        description = "Database user";
      };
    };

    redis = {
      host = lib.mkOption {
        type = lib.types.str;
        default = "localhost";
        description = "Redis host";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 6379;
        description = "Redis port";
      };

      databaseIndex = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "Redis database index";
      };
    };

    accessControlRules = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      example = [
        {
          domain = ["*.example.com"];
          policy = "one_factor";
        }
      ];
      description = "Access control rules for protected domains";
    };
  };

  config = lib.mkIf cfg.enable {
    # Créer le groupe et l'utilisateur authelia
    users.users.authelia = {
      isSystemUser = true;
      group = "authelia";
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.authelia = {};

    # Service Redis local si besoin
    services.redis.servers.authelia = lib.mkIf (cfg.redis.host == "localhost") {
      enable = true;
      port = cfg.redis.port;
      bind = "127.0.0.1";
    };

    # Service PostgreSQL local si besoin
    services.postgresql = lib.mkIf (cfg.database.type == "postgres" && cfg.database.host == "localhost") {
      enable = true;
      ensureDatabases = [cfg.database.name];
      ensureUsers = [
        {
          name = cfg.database.user;
          ensureDBOwnership = true;
        }
      ];
    };

    # Secrets SOPS
    sops.secrets = {
      authelia_jwt_secret = {
        sopsFile = ../../../secrets/secrets.yaml;
        owner = "authelia";
        group = "authelia";
        mode = "0400";
        restartUnits = ["authelia.service"];
      };
      authelia_storage_encryption_key = {
        sopsFile = ../../../secrets/secrets.yaml;
        owner = "authelia";
        group = "authelia";
        mode = "0400";
        restartUnits = ["authelia.service"];
      };
    } // lib.optionalAttrs (cfg.database.type == "postgres") {
      authelia_db_password = {
        sopsFile = ../../../secrets/secrets.yaml;
        owner = "authelia";
        group = "authelia";
        mode = "0400";
        restartUnits = ["authelia.service"];
      };
    };

    # Service systemd Authelia
    systemd.services.authelia = {
      description = "Authelia authentication and authorization server";
      after = ["network.target"]
        ++ lib.optional (cfg.redis.host == "localhost") "redis-authelia.service"
        ++ lib.optional (cfg.database.type == "postgres" && cfg.database.host == "localhost") "postgresql.service";
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = "authelia";
        Group = "authelia";
        ExecStart = "${pkgs.authelia}/bin/authelia --config ${configFile}";
        Restart = "on-failure";
        RestartSec = "5s";

        # Hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [cfg.dataDir];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
        RestrictNamespaces = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
      };
    };

    # Créer le fichier users_database.yml par défaut s'il n'existe pas
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0700 authelia authelia -"
      "f ${cfg.usersFile} 0600 authelia authelia -"
    ];

    # Ouvrir les ports firewall
    networking.firewall.allowedTCPPorts = [cfg.port];
  };
}
