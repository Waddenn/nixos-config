{
  config,
  lib,
  pkgs,
  ...
}: {
  options.services.githubRunner.enable = lib.mkEnableOption "Enable GitHub Actions runner";

  config = lib.mkIf config.services.githubRunner.enable {
    services.github-runners = {
      runner1 = {
        replace = true;
        token = "3VY1Cl29odeCWwijad5gs9TX6qkDJ";
        url = "https://github.com/tom/nixos-config";
        extraLabels = ["nixos" "self-hosted"];
        workDir = "/var/lib/github-runner";
      };
    };
  };
}
