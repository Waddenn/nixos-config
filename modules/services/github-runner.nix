{
  config,
  lib,
  pkgs,
  ...
}: {
  options.services.ggithubRunner.enable = lib.mkEnableOption "Enable GitHub Actions runner";

  config = lib.mkIf config.services.githubRunner.enable {
    services.github-runners = {
      runner1 = {
        replace = true;
        # token = "";
        url = "https://github.com/tom/nixos-config";
        extraLabels = ["nixos" "self-hosted"];
        workDir = "/var/lib/github-runner";
      };
    };
  };
}
