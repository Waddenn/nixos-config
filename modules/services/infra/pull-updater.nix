{
  config,
  lib,
  pkgs,
  ...
}: {
  options.my-services.infra.pull-updater = {
    enable = lib.mkEnableOption "Enable the revision-aware deployment agent";

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
  };

  config = lib.mkIf config.my-services.infra.pull-updater.enable {
    systemd.services."internal-pull-update@" = {
      description = "Apply an orchestrator-selected NixOS revision (%i)";
      stopIfChanged = false;
      restartIfChanged = false;
      path = [pkgs.git pkgs.nixos-rebuild pkgs.gnugrep pkgs.gnused pkgs.gawk pkgs.coreutils pkgs.openssh pkgs.bash pkgs.util-linux];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        WorkingDirectory = config.my-services.infra.pull-updater.repoDir;
        StateDirectory = "internal-pull-update";
        ExecStart = "${pkgs.bash}/bin/bash ${../../../scripts/pull-update-host.sh} %i";
        Environment = [
          "REPO_DIR=${config.my-services.infra.pull-updater.repoDir}"
          "GIT_REMOTE=${config.my-services.infra.pull-updater.gitRemote}"
          "GIT_BRANCH=${config.my-services.infra.pull-updater.gitBranch}"
        ];
      };
    };
  };
}
