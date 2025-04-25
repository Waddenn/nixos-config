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
        tokenFile = "/var/lib/github-runner/nixos-runner/.current-token";
        url = "https://github.com/Waddenn/nixos-config";
        extraLabels = ["nixos" "self-hosted"];
        workDir = "/var/lib/github-runner/nixos-runner";
        serviceOverrides = {
          DynamicUser = false;
          ProtectSystem = false;
          ProtectHome = false;
        };
      };
    };
  };
}
