{
  config,
  lib,
  pkgs,
  ...
}: {
  options.githubRunner.enable = lib.mkEnableOption "Enable GitHub Actions runner";

  config = lib.mkIf config.githubRunner.enable {
    environment.etc = {
      "secrets/github-runner.token" = {
        source = ../../secrets/github-runner.token;
        user = "runner";
        group = "runner";
        mode = "0400";
      };
    };

    users.groups.runner = {};
    users.users.runner = {
      isSystemUser = true;
      group = "runner";
      home = "/var/lib/github-runner";
      createHome = true;
    };

    sops.secrets.cf_api_token = {
      format = "dotenv";
      sopsFile = ../../secrets/github-runner.env.enc;
    };

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
          trusted-users = ["root" "runner"];
        };
      };
    };

    nix.settings.sandbox = false;
  };
}
