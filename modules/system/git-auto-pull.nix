{
  config,
  pkgs,
  lib,
  ...
}: let
  repoPath = "/home/nixos/nixos-config";
in {
  options.gitAutoPull.enable = lib.mkEnableOption "Enable periodic git pull of the NixOS config repo";

  config = lib.mkIf config.gitAutoPull.enable {
    systemd.services.git-auto-pull = {
      description = "Periodically git pull the NixOS config repo";
      serviceConfig = {
        Type = "oneshot";
        User = "nixos";
        WorkingDirectory = repoPath;
        ExecStart = "${pkgs.git}/bin/git pull";
      };
    };

    systemd.timers.git-auto-pull = {
      description = "Timer for git-auto-pull";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        Unit = "git-auto-pull.service";
      };
    };
  };
}
