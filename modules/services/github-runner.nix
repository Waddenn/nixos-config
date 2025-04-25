{
  config,
  lib,
  pkgs,
  ...
}: {
  options.services.githubRunner.enable = lib.mkEnableOption "Enable GitHub Actions runner";

  config = lib.mkIf config.services.githubRunner.enable {
    services.github-runners = {
      nixos-runner = {
        replace = true;
        tokenFile = "/run/secrets/github-runner/nixos.token";
        url = "https://github.com/Waddenn/nixos-config";
        extraLabels = ["nixos" "self-hosted"];
        workDir = "/var/lib/github-runner";
      };
    };
  };
}
