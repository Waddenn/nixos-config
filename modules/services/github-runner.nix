{ config, lib, pkgs, ... }:
{
  options.githubRunner.enable = lib.mkEnableOption "Enable GitHub Actions runner";

  config = lib.mkIf config.githubRunner.enable {

    #### Secrets (token) -> /etc/secrets/github-runner.token
    environment.etc."secrets/github-runner.token" = {
      # Remplace par ta vraie source (sops, age, bind-mount, etc.)
      # ex: source = /var/keys/github-runner.token;
      source = /var/keys/github-runner.token;
      user = "root";
      group = "root";
      mode = "0400";
    };

    #### Compte runner
    users.groups.runner = { };
    users.users.runner = {
      isSystemUser = true;
      group = "runner";
      home = "/var/lib/github-runner";
      createHome = true;
      # Si tes jobs utilisent docker, décommente :
      # extraGroups = [ "docker" ];
    };

    #### Dossier de travail du runner
    systemd.tmpfiles.rules = [
      "d /var/github-runner-work 0750 runner runner -"
    ];

    #### GitHub runner
    services.github-runners.nixos-runner = {
      enable = true;
      replace = true;

      url = "https://github.com/Waddenn/nixos-config";
      tokenFile = "/etc/secrets/github-runner.token";
      extraLabels = [ "nixos" "self-hosted" ];

      package = pkgs.github-runner;

      user = "runner";
      group = "runner";
      workDir = "/var/github-runner-work";

      extraPackages = with pkgs; [
        alejandra
        nix-eval-jobs
        nix-fast-build
        curl
      ];

      # Correct: overrides systemd au niveau "Service"
      serviceOverrides = {
        Service = {
          ProtectSystem = "full";
          ProtectHome = "read-only";
          PrivateDevices = false;     # true si tu veux un sandbox plus strict
          RestrictNamespaces = false; # souvent nécessaire en LXC
          # SystemCallFilter peut être une liste (recommandé) :
          # SystemCallFilter = [ "@system-service" ];
        };
      };

      extraEnvironment = {
        NIX_CONFIG = "sandbox = false";
      };
    };

    #### Nix
    nix.settings = {
      sandbox = false;                     # LXC
      trusted-users = [ "root" "runner" ];
      # Evite l’avertissement "download buffer is full"
      download-buffer-size = 536870912;    # 512 MiB
    };

    #### LXC: couper oomd qui casse le switch
    systemd.oomd.enable = false;
    systemd.services.systemd-oomd.enable = false;
    systemd.sockets.systemd-oomd.enable = false;

    #### (Optionnel) Docker si tes jobs l’utilisent
    # virtualisation.docker.enable = true;
    # virtualisation.docker.autoPrune.enable = true;
    # virtualisation.docker.liveRestore = false; # plus simple pour LXC
  };
}
