{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my-services.auth.authelia;

  # Configuration Authelia base (sans secrets)
  autheliaConfigBase = {
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
      # secret sera lu depuis AUTHELIA_SESSION_SECRET env var

      redis = {
        host = cfg.redis.host;
        port = cfg.redis.port;
        database_index = cfg.redis.databaseIndex;
      };
    };

    # Storage configuré selon le type
    storage =
      if cfg.database.type == "postgres"
      then {
        postgres = {
          address = "tcp://${cfg.database.host}:${toString cfg.database.port}";
          database = cfg.database.name;
          username = cfg.database.user;
          # password sera lu depuis AUTHELIA_STORAGE_POSTGRES_PASSWORD env var
        };
        # encryption_key sera lu depuis AUTHELIA_STORAGE_ENCRYPTION_KEY env var
      }
      else {
        local = {
          path = "${cfg.dataDir}/db.sqlite3";
        };
        # encryption_key sera lu depuis AUTHELIA_STORAGE_ENCRYPTION_KEY env var
      };

    notifier = {
      disable_startup_check = true;
      filesystem = {
        filename = "${cfg.dataDir}/notification.txt";
      };
    };

    access_control = {
      # Utiliser one_factor par défaut si pas de règles (deny nécessite des règles)
      default_policy =
        if cfg.accessControlRules == []
        then "one_factor"
        else cfg.defaultPolicy;

      rules = cfg.accessControlRules;
    };

    # jwt_secret sera lu depuis AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET env var
    identity_validation.reset_password = {};
  };

  configFormat = pkgs.formats.yaml {};
  configFile = configFormat.generate "authelia-config.yml" autheliaConfigBase;
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
      authelia_session_secret = {
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

    # Script pour générer le fichier d'environnement avec les secrets
    systemd.services.authelia-env-setup = {
      description = "Setup Authelia environment file with secrets";
      before = ["authelia.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = let
        secretsEnv = ''
          AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET=$(cat ${config.sops.secrets.authelia_jwt_secret.path})
          AUTHELIA_SESSION_SECRET=$(cat ${config.sops.secrets.authelia_session_secret.path})
          AUTHELIA_STORAGE_ENCRYPTION_KEY=$(cat ${config.sops.secrets.authelia_storage_encryption_key.path})
        ''
        + lib.optionalString (cfg.database.type == "postgres") ''
          AUTHELIA_STORAGE_POSTGRES_PASSWORD=$(cat ${config.sops.secrets.authelia_db_password.path})
        '';
      in ''
        mkdir -p /run/authelia
        cat > /run/authelia/env <<'EOF'
        ${secretsEnv}
        EOF
        chmod 600 /run/authelia/env
        chown authelia:authelia /run/authelia/env
      '';
    };

    # Service systemd Authelia
    systemd.services.authelia = {
      description = "Authelia authentication and authorization server";
      after = ["network.target" "authelia-env-setup.service"]
        ++ lib.optional (cfg.redis.host == "localhost") "redis-authelia.service"
        ++ lib.optional (cfg.database.type == "postgres" && cfg.database.host == "localhost") "postgresql.service";
      requires = ["authelia-env-setup.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = "authelia";
        Group = "authelia";
        EnvironmentFile = "/run/authelia/env";
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
      "d /run/authelia 0700 authelia authelia -"
    ];

    # Ouvrir les ports firewall
    networking.firewall.allowedTCPPorts = [cfg.port];
  };
}
