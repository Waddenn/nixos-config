{
  config,
  lib,
  pkgs,
  ...
}: {
  options.githubRunner.enable = lib.mkEnableOption "Enable GitHub Actions runner";

  config = lib.mkIf config.githubRunner.enable {
    services.github-runners = {
      nixos-runner = {
        enable = true;
        replace = true;
        tokenFile = "/run/secrets/github-runner/nixos.token";
        url = "https://github.com/Waddenn/nixos-config";
        extraLabels = ["nixos" "self-hosted"];
        workDir = "/var/lib/github-runner";
        user = "github-runner";
        group = "github-runner";
      };
    };

    users.groups.github-runner = {};
    users.users.github-runner = {
      isSystemUser = true;
      group = "github-runner";
      home = "/var/lib/github-runner";
      createHome = true;
    };
  };
}
