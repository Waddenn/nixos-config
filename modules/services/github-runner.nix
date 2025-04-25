{
  config,
  lib,
  pkgs,
  ...
}: {
  options.githubRunner.enable = lib.mkEnableOption "Enable GitHub Actions runner";

  config = lib.mkIf config.githubRunner.enable {
    # 🧑‍💻 Utilisateur dédié
    users.groups.runner = {};
    users.users.runner = {
      isSystemUser = true;
      group = "runner";
      home = "/var/lib/github-runner";
      createHome = true;
    };

    # 🔐 Token GitHub via SOPS
    sops.secrets.github-runner = {
      owner = "runner";
      group = "runner";
      mode = "0400";
      sopsFile = ../../secrets/github-runner.token.enc;
    };

    # 🧪 Exemple d'un autre secret .env
    sops.secrets.cf_api_token = {
      format = "dotenv";
      sopsFile = ../../secrets/github-runner.env.enc;
    };

    # ⚙️ GitHub Runner
    services.github-runners = {
      nixos-runner = {
        enable = true;
        url = "https://github.com/Waddenn/nixos-config";
        tokenFile = config.sops.secrets.github-runner.path;

        extraLabels = ["nixos" "self-hosted"];
        package = pkgs.github-runner;

        user = "runner";
        group = "runner";
        workDir = "/var/github-runner-work";

        extraPackages = with pkgs; [alejandra nix-eval-jobs];

        serviceOverrides = {
          ProtectSystem = "full";
          ProtectHome = "read-only";
          PrivateDevices = false;
          SystemCallFilter = "default";
          RestrictNamespaces = false;
        };

        extraEnvironment = {
          NIX_CONFIG = "sandbox = false";
        };
      };
    };

    nix.settings = {
      sandbox = false;
      trusted-users = ["root" "runner"];
    };
  };
}
