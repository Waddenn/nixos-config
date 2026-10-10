{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my-services.infra.classeur-cd-activation;
  settings = pkgs.writeText "classeur-activation-settings.json" (builtins.toJSON {
    state = "/var/lib/le-classeur";
    staging = "/var/lib/le-classeur-staging";
    receiver = ../../scripts/classeur-stage-release.py;
    path = lib.makeBinPath [pkgs.coreutils pkgs.systemd pkgs.util-linux];
    systemctl = "${pkgs.systemd}/bin/systemctl";
    systemdRun = "${pkgs.systemd}/bin/systemd-run";
    runuser = "${pkgs.util-linux}/bin/runuser";
    env = "${pkgs.coreutils}/bin/env";
    node = "${pkgs.nodejs_24}/bin/node";
    python = "${pkgs.python3}/bin/python3";
    caBundle = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    environmentFile = config.sops.templates.classeur-runtime-env.path;
    publicOrigin = "https://classeur.hexaflare.net";
    environment = {
      NODE_ENV = "production";
      LD_LIBRARY_PATH = lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib];
      APP_ENV = "beta";
      APP_RUNTIME = "node";
      APP_ORIGIN = "https://classeur.hexaflare.net";
      HOST = "127.0.0.1";
      DATABASE_URL = "postgresql://le_classeur_app@localhost/le_classeur_beta?host=/run/postgresql";
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    };
  });
  activate = pkgs.writeShellScript "classeur-activate" ''
    export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    exec ${pkgs.python3}/bin/python3 ${../../scripts/classeur-activate-release.py} ${settings}
  '';
  forced = pkgs.writeShellScript "classeur-activation-command" ''
    set -euo pipefail
    printf '%s' "''${SSH_ORIGINAL_COMMAND:-}" | /run/wrappers/bin/sudo -n ${activate}
  '';
in {
  options.my-services.infra.classeur-cd-activation = {
    enable = lib.mkEnableOption "Le classeur restricted code-only release activation";
    publicKey = lib.mkOption {
      type = lib.types.str;
      default = lib.removeSuffix "\n" (builtins.readFile ./classeur-activation-public-key.pub);
      description = "Dedicated activation public key, distinct from staging and controller access.";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.match "ssh-ed25519 [A-Za-z0-9+/=]+( [^\n]*)?" cfg.publicKey != null;
        message = "Classeur activation requires a dedicated ed25519 public key.";
      }
    ];
    users.groups.classeur-activation = {};
    users.users.classeur_activate = {
      isSystemUser = true;
      group = "classeur-activation";
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = [''restrict,command="${forced}" ${cfg.publicKey}''];
    };
    # Empty quoted argv in sudoers means no arguments, not arbitrary arguments.
    # The immutable wrapper accepts only one validated protocol line on stdin.
    security.sudo.extraRules = [
      {
        users = ["classeur_activate"];
        commands = [
          {
            command = ''${activate} ""'';
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
    services.openssh.extraConfig = lib.mkAfter ''
      Match User classeur_activate
        AuthenticationMethods publickey
        PasswordAuthentication no
        KbdInteractiveAuthentication no
        ForceCommand ${forced}
        DisableForwarding yes
        PermitTTY no
        PermitTunnel no
        X11Forwarding no
      Match all
    '';
  };
}
