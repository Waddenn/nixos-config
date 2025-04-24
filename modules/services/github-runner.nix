{
  config,
  lib,
  pkgs,
  ...
}: {
  options.services.github-runner.enable = lib.mkEnableOption "Enable GitHub Actions runner";

  config = lib.mkIf config.services.github-runner.enable {
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
