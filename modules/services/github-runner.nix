{
  config,
  lib,
  pkgs,
  ...
}: {
  options.githubRunner.enable = lib.mkEnableOption "Enable GitHub Actions runner";

  config = lib.mkIf config.githubRunner.enable {
    systemd.tmpfiles.rules = [
      "d /var/lib/github-runner 0750 github-runner github-runner -"
    ];

    services.github-runners = {
      nixos-runner = {
        enable = true;
        replace = true;
        user = "github-runner";
        group = "github-runner";
        tokenFile = "/run/secrets/github-runner/nixos.token";
        url = "https://github.com/Waddenn/nixos-config";
        extraLabels = ["nixos" "self-hosted"];
        workDir = "/var/lib/github-runner";
      };
    };
  };
}
