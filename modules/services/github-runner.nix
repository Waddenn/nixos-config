{
  config,
  lib,
  pkgs,
  ...
}: {
  options.githubRunner.enable = lib.mkEnableOption "Enable GitHub Actions runner";

  config = lib.mkIf config.githubRunner.enable {
    # 🔐 Token GitHub
    environment.etc = {
      "secrets/github-runner.token" = {
        source = ../../secrets/github-runner.token;
        user = "runner";
        group = "runner";
        mode = "0400";
      };
    };

    # 👤 Utilisateur système pour exécuter le runner
    users.groups.runner = {};
    users.users.runner = {
      isSystemUser = true;
      group = "runner";
      home = "/var/lib/github-runner";
      createHome = true;
    };

    # 📦 Runner GitHub
    services.github-runners = {
      nixos-runner = {
        enable = true;
        url = "https://github.com/Waddenn/nixos-config";
        tokenFile = "/etc/secrets/github-runner.token";
        extraLabels = ["nixos" "self-hosted"];
        package = pkgs.github-runner;

        user = "runner";
        group = "runner";

        workDir = "/var/github-runner-work";

        serviceOverrides = {
          ProtectSystem = "off";
          PrivateDevices = false;
          ProtectHome = false;
          SystemCallFilter = "default";
          CapabilityBoundingSet = "~";
          NoNewPrivileges = false;
          RestrictAddressFamilies = [];
          RestrictNamespaces = false;
          LockPersonality = false;
          ProtectKernelModules = false;
          ProtectKernelTunables = false;
          ProtectControlGroups = false;
          RestrictRealtime = false;
          ProtectClock = false;
        };

        extraEnvironment = {
          NIX_CONFIG = "sandbox = false";
        };
      };
    };

    # 🧰 Config globale pour Nix
    nix.settings.sandbox = false;
  };
}
