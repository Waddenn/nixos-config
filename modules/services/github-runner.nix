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
        workDir = "//home/nixos/github-runner";
      };
    };
  };
}
