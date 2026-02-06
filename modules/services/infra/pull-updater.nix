{
  config,
  lib,
  pkgs,
  ...
}: {
  options.my-services.infra.pull-updater = {
    enable = lib.mkEnableOption "Enable local pull-based host updates";

    canary = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Mark this host as canary for orchestrated rollouts.";
    };

    repoDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/nixos/nixos-config";
      description = "Repository directory used for local pull updates.";
    };

    gitRemote = lib.mkOption {
      type = lib.types.str;
      default = "origin";
      description = "Git remote used for pull updates.";
    };

    gitBranch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Git branch used for pull updates.";
    };

    timerInterval = lib.mkOption {
      type = lib.types.str;
      default = "60m";
      description = "Interval between pull update runs.";
    };

    randomizedDelay = lib.mkOption {
      type = lib.types.str;
      default = "1m";
      description = "Randomized delay for timer runs.";
    };
  };

  config = lib.mkIf config.my-services.infra.pull-updater.enable {
    systemd.services.internal-pull-update = {
      description = "Internal Pull Updater";
      stopIfChanged = false;
      restartIfChanged = false;
      path = [pkgs.git pkgs.nixos-rebuild pkgs.gnugrep pkgs.gawk pkgs.coreutils pkgs.openssh pkgs.bash];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        WorkingDirectory = config.my-services.infra.pull-updater.repoDir;
        ExecStart = "${pkgs.bash}/bin/bash ${../../../scripts/pull-update-host.sh}";
        Environment = [
          "REPO_DIR=${config.my-services.infra.pull-updater.repoDir}"
          "GIT_REMOTE=${config.my-services.infra.pull-updater.gitRemote}"
          "GIT_BRANCH=${config.my-services.infra.pull-updater.gitBranch}"
        ];
      };
    };

    systemd.timers.internal-pull-update = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = config.my-services.infra.pull-updater.timerInterval;
        RandomizedDelaySec = config.my-services.infra.pull-updater.randomizedDelay;
      };
    };
  };
}
