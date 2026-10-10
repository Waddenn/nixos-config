{
  config,
  lib,
  pkgs,
  service,
  ...
}: let
  state = "/var/lib/le-classeur";
  node = "${pkgs.nodejs_24}/bin/node";
  proxyAllow = lib.concatMapStringsSep "\n" (cidr: "allow ${cidr};") (service.application.trustedProxyCIDRs or ["127.0.0.1"]);
  runtime = {
    User = "le_classeur_app";
    Group = "le-classeur";
    WorkingDirectory = "${state}/current";
    EnvironmentFile = config.sops.templates.classeur-runtime-env.path;
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    RestrictSUIDSGID = true;
    RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
    UMask = "0077";
    LimitNOFILE = 4096;
  };
  environment = {
    NODE_ENV = "production";
    # Sharp's Linux prebuilt libvips requires the C++ runtime in a NixOS guest.
    LD_LIBRARY_PATH = lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib];
    APP_ENV = "beta";
    APP_RUNTIME = "node";
    APP_ORIGIN = "https://classeur.hexaflare.net";
    HOST = "127.0.0.1";
    PORT = "8083";
    DATABASE_URL = "postgresql://le_classeur_app@localhost/le_classeur_beta?host=/run/postgresql";
  };
in {
  imports = [./classeur-cd-staging.nix];
  my-services.infra.classeur-cd-staging.enable = true;
  sops.secrets.classeur-environment = {
    sopsFile = ../secrets/classeur.yaml;
    mode = "0400";
    restartUnits = ["le-classeur.service"];
  };
  sops.secrets.classeur-turnstile = {
    sopsFile = ../secrets/classeur-turnstile.yaml;
    key = "turnstile-secret-key";
    mode = "0400";
    restartUnits = ["le-classeur.service"];
  };
  sops.secrets.classeur-session = {
    sopsFile = ../secrets/classeur-session.yaml;
    key = "session-secret";
    mode = "0400";
    restartUnits = ["le-classeur.service"];
  };
  sops.templates.classeur-runtime-env = {
    owner = "le_classeur_app";
    group = "le-classeur";
    mode = "0400";
    content = ''
      ${config.sops.placeholder.classeur-environment}
      SESSION_SECRET=${config.sops.placeholder.classeur-session}
      TURNSTILE_SECRET_KEY=${config.sops.placeholder.classeur-turnstile}
    '';
  };
  sops.secrets.classeur-origin-token = {
    sopsFile = ../secrets/classeur-origin.yaml;
    mode = "0400";
    restartUnits = ["nginx.service"];
  };
  sops.templates.classeur-origin-auth = {
    owner = config.services.nginx.user;
    mode = "0400";
    content = ''
      map $http_authorization $classeur_origin_authorized {
        default 0;
        "Bearer ${config.sops.placeholder.classeur-origin-token}" 1;
      }
    '';
  };
  users.groups.le-classeur = {};
  users.users.le_classeur_app = {
    isSystemUser = true;
    group = "le-classeur";
  };
  users.users.le_classeur_beta_owner = {
    isSystemUser = true;
    group = "le-classeur";
  };
  systemd.tmpfiles.rules = [
    "d ${state} 0750 root le-classeur -"
    "d ${state}/releases 0750 root le-classeur -"
    "d /var/backup/le-classeur 0700 postgres postgres -"
  ];
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    enableTCPIP = false;
    ensureDatabases = ["le_classeur_beta"];
    ensureUsers = [
      {name = "le_classeur_beta_owner";}
      {name = "le_classeur_app";}
    ];
    authentication = lib.mkForce ''
      local all postgres peer
      local le_classeur_beta le_classeur_beta_owner peer
      local le_classeur_beta le_classeur_app peer
      local all all reject
    '';
    settings = {
      max_connections = 50;
      shared_buffers = "512MB";
      work_mem = "8MB";
      log_statement = "none";
      log_min_error_statement = "panic";
    };
  };
  # Restore owns the schema and grants runtime privileges explicitly. No automatic
  # migration or broad default table grant can change a reviewed release.
  # ensureUsers/ensureDatabases run in postgresql-setup.service, after the
  # server starts. Apply ownership only after those roles and DB exist.
  systemd.services.postgresql-setup.postStart = lib.mkAfter ''
    ${config.services.postgresql.package}/bin/psql -v ON_ERROR_STOP=1 -d postgres <<'SQL'
    ALTER DATABASE le_classeur_beta OWNER TO le_classeur_beta_owner;
    REVOKE ALL ON DATABASE le_classeur_beta FROM PUBLIC;
    GRANT CONNECT ON DATABASE le_classeur_beta TO le_classeur_app;
    SQL
  '';
  services.nginx = {
    enable = true;
    # The /run secret include exists only on the guest; nginx validates it at start.
    validateConfigFile = false;
    # Rendered only in /run by sops-nix; no token appears in the store or logs.
    # NixOS emits this before its own upgrade map; adding the directive to
    # appendHttpConfig places it too late and nginx reports a duplicate.
    mapHashBucketSize = 128;
    appendHttpConfig = ''
      include ${config.sops.templates.classeur-origin-auth.path};
      # CF-Connecting-IP is forwarded only by the authenticated Caddy origin.
      # Do not rewrite remote_addr: the ingress allow/deny checks the proxy peer.
      map $http_cf_connecting_ip $classeur_client_key {
        "" $binary_remote_addr;
        default $http_cf_connecting_ip;
      }
      map $uri $classeur_dynamic_key {
        default $classeur_client_key;
        ~^/assets/ "";
        ~^/(api/admin|__admin-api)/assets/ "";
        ~^/accueil/illustrations/ "";
      }
      map $uri $classeur_artwork_key {
        default "";
        ~^/(api/admin|__admin-api)/assets/ $classeur_client_key;
        ~^/accueil/illustrations/ $classeur_client_key;
      }
      limit_req_zone $classeur_dynamic_key zone=classeur_dynamic:10m rate=15r/s;
      limit_req_zone $classeur_artwork_key zone=classeur_artwork:10m rate=20r/s;
    '';
    virtualHosts.classeur = {
      listen = [
        {
          addr = "0.0.0.0";
          port = service.application.port;
        }
      ];
      locations."= /health" = {
        proxyPass = "http://127.0.0.1:8083";
        extraConfig = ''
          proxy_set_header Host classeur.hexaflare.net;
          proxy_set_header X-Forwarded-Proto https;
          proxy_set_header CF-Connecting-IP "";
          limit_req zone=classeur_dynamic burst=60 nodelay;
          limit_req_status 429;
        '';
      };
      locations."/" = {
        proxyPass = "http://127.0.0.1:8083";
        extraConfig = ''
          proxy_set_header Host classeur.hexaflare.net;
          proxy_set_header X-Forwarded-Proto https;
          proxy_set_header X-Forwarded-Host classeur.hexaflare.net;
          ${proxyAllow}
          deny all;
          if ($classeur_origin_authorized = 0) { return 403; }
          proxy_set_header Authorization "";
          # Caddy overwrites the bearer header and validates the Cloudflare peer.
          proxy_set_header X-Forwarded-For $http_cf_connecting_ip;
          proxy_set_header CF-Connecting-IP $http_cf_connecting_ip;
          # Allow two full binder views to fetch thumbnails together. Requests
          # rejected here never reach Node or PostgreSQL; static bundles are exempt.
          limit_req zone=classeur_dynamic burst=60 nodelay;
          limit_req zone=classeur_artwork burst=120 nodelay;
          limit_req_status 429;
          client_max_body_size 20m;
        '';
      };
    };
  };
  # A bearer token is mandatory even for loopback: userspace Tailscale may proxy
  # remote peers through loopback. Health remains reachable for provisioner checks.
  networking.firewall.allowedTCPPorts = [service.application.port];
  systemd.services.le-classeur = {
    description = "Le classeur Node application (operator-selected release)";
    wantedBy = ["multi-user.target"];
    after = ["postgresql-setup.service" "network-online.target"];
    wants = ["network-online.target"];
    requires = ["postgresql-setup.service"];
    inherit environment;
    unitConfig.ConditionPathExists = "${state}/current/build/server/index.js";
    serviceConfig =
      runtime
      // {
        ExecStart = "${node} ${state}/current/build/server/index.js";
        Restart = "on-failure";
        RestartSec = "5s";
        MemoryMax = "2G";
      };
  };
  systemd.services.le-classeur-cleanup = {
    description = "Expire Le classeur trade reservations";
    after = ["postgresql-setup.service" "le-classeur.service"];
    requires = ["postgresql-setup.service"];
    inherit environment;
    unitConfig.ConditionPathExists = "${state}/current/build/server/index.js";
    serviceConfig =
      runtime
      // {
        Type = "oneshot";
        ExecStart = "${node} ${state}/current/build/server/index.js --cleanup";
        TimeoutStartSec = "50s";
        MemoryMax = "512M";
      };
  };
  systemd.timers.le-classeur-cleanup = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* *:*:00";
      Persistent = true;
    };
  };
  systemd.services.le-classeur-backup = {
    description = "Versioned logical backup of Le classeur including database assets";
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      UMask = "0077";
    };
    after = ["postgresql-setup.service"];
    requires = ["postgresql-setup.service"];
    path = [config.services.postgresql.package pkgs.coreutils pkgs.findutils];
    script = ''
      set -eu
      stamp=$(date -u +%Y%m%dT%H%M%SZ)
      target=/var/backup/le-classeur/$stamp.dump
      pg_dump --format=custom --file="$target.tmp" le_classeur_beta
      pg_restore --list "$target.tmp" >/dev/null
      mv "$target.tmp" "$target"
      sha256sum "$target" > "$target.sha256"
      # Retention only after a newly completed dump; off-host copies are required.
      find /var/backup/le-classeur -name '*.dump*' -mtime +14 -delete
    '';
  };
  systemd.timers.le-classeur-backup = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 02:15:00";
      Persistent = true;
    };
  };
}
