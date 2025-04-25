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
        source = /home/nixos/github-runner.token;
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

    services.github-runners = {
      nixos-runner = {
        enable = true;
        replace = true;
        url = "https://github.com/Waddenn/nixos-config";
        tokenFile = "/etc/secrets/github-runner.token";
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
