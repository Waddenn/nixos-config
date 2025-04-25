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
        user = "root";
        group = "root";
        mode = "0400";
      };
    };

    services.github-runners = {
      nixos-runner = {
        enable = true;
        url = "https://github.com/Waddenn/nixos-config";
        tokenFile = "/etc/secrets/github-runner.token";
        extraLabels = ["nixos" "self-hosted"];
        package = pkgs.github-runner;

        user = "root";
        group = "root";

        workDir = "/var/github-runner-work";

        serviceOverrides = {
          ProtectSystem = "off";
          PrivateDevices = false;
          ProtectHome = false;
          SystemCallFilter = "~@system-service"; # ou juste "default" pour ne pas filtrer du tout
          CapabilityBoundingSet = "~CAP_SYS_ADMIN"; # ou supprime cette ligne si tu la définis ailleurs
          NoNewPrivileges = false;
        };
      };
    };
  };
}
