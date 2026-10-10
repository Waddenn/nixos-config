{
  config,
  lib,
  pkgs,
  ...
}: {
  options.my-services.infra.classeur-backup.enable = lib.mkEnableOption "Verified Le classeur backups pulled by dev-nixos to a separate storage host";
  config = lib.mkIf config.my-services.infra.classeur-backup.enable {
    assertions = [
      {
        assertion = config.networking.hostName == "dev-nixos";
        message = "Only dev-nixos may hold the Le classeur backup transport credentials";
      }
    ];
    systemd.services.le-classeur-offhost-backup = {
      description = "Pull verified Le classeur database dump to separate storage";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      path = [pkgs.openssh pkgs.coreutils];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = "${pkgs.python3}/bin/python3 ${../../../scripts/classeur-offhost-backup.py}";
        TimeoutStartSec = "30min";
        UMask = "0077";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ReadWritePaths = ["/var/backup/le-classeur-offhost"];
      };
    };
    systemd.tmpfiles.rules = ["d /var/backup/le-classeur-offhost 0700 root root -"];
    systemd.timers.le-classeur-offhost-backup = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "*-*-* 03:15:00";
        Persistent = true;
        RandomizedDelaySec = "5min";
      };
    };
  };
}
