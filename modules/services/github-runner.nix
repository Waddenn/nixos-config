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
        tokenFile = "/var/lib/github-runner/nixos-runner/.token";
        url = "https://github.com/Waddenn/nixos-config";
        extraLabels = ["nixos" "self-hosted"];
        workDir = "/var/lib/github-runner/nixos-runner";
        serviceOverrides = {
          StateDirectory = "github-runner/nixos-runner";
        };
      };
    };
  };
}
