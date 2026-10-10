{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my-services.infra.classeur-cd-staging;
  receiver = ../../scripts/classeur-stage-release.py;
  forcedCommand = "${pkgs.python3}/bin/python3 ${receiver}";
in {
  options.my-services.infra.classeur-cd-staging = {
    enable = lib.mkEnableOption "Le classeur isolated CD staging (never activates releases)";
    publicKey = lib.mkOption {
      type = lib.types.str;
      default = lib.removeSuffix "\n" (builtins.readFile ./classeur-cd-public-key.pub);
      description = "Dedicated staging-only public SSH key; private key stays in GitHub environment secrets.";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.match "ssh-ed25519 [A-Za-z0-9+/=]+( [^\n]*)?" cfg.publicKey != null;
        message = "Classeur CD requires a dedicated ed25519 public key.";
      }
    ];
    users.groups.classeur-cd = {};
    users.users.classeur_cd = {
      isSystemUser = true;
      group = "classeur-cd";
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = [
        ''restrict,command="${forcedCommand}" ${cfg.publicKey}''
      ];
    };
    systemd.tmpfiles.rules = [
      "d /var/lib/le-classeur-staging 0700 classeur_cd classeur-cd -"
    ];
    # Receiver never gets sudo, service control, DB credentials or the app group.
    services.openssh.extraConfig = lib.mkAfter ''
      Match User classeur_cd
        AuthenticationMethods publickey
        PasswordAuthentication no
        KbdInteractiveAuthentication no
        ForceCommand ${forcedCommand}
        DisableForwarding yes
        PermitTTY no
        PermitTunnel no
        X11Forwarding no
      Match all
    '';
  };
}
