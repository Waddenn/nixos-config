{
  config,
  lib,
  pkgs,
  ...
}: let
  tokenPath = "/secrets/github-runner.token";
in {
  options.githubRunner.enable = lib.mkEnableOption "Enable GitHub Actions runner";

  config = lib.mkIf config.githubRunner.enable {
    services.github-runners = {
      nixos-runner = {
        enable = true;
        url = "https://github.com/Waddenn/nixos-config";
        tokenFile = tokenPath;
        extraLabels = ["nixos" "self-hosted"];
        package = pkgs.github-runner;

        serviceOverrides = {
          ProtectSystem = "off";
          PrivateDevices = false;
          ProtectHome = false;
        };
      };
    };
  };
}
