{
  config,
  lib,
  pkgs,
  ...
}: {
  options.githubRunner.enable = lib.mkEnableOption "Enable GitHub Actions runner";

  config = lib.mkIf config.githubRunner.enable {
    # 1) on importe le token depuis un fichier hors store (ici : /root/github-runner.token)
    environment.etc = {
      "secrets/github-runner.token" = {
        source = ../../secrets/github-runner.token;
        user = "root";
        group = "root";
        mode = "0400";
      };
    };

    # 2) on pointe le runner dessus
    services.github-runners = {
      nixos-runner = {
        enable = true;
        url = "https://github.com/Waddenn/nixos-config";
        tokenFile = "/etc/secrets/github-runner.token";
        extraLabels = ["nixos" "self-hosted"];
        package = pkgs.github-runner;

        user = "root";
        group = "root";

        serviceConfig = {
          # mkForce pour écraser la définition upstream (qui est bool)
          DynamicUser = lib.mkForce false;
          StateDirectory = lib.mkForce "github-runner/nixos-runner";
          LogsDirectory = lib.mkForce "github-runner/nixos-runner";

          # On désactive le sandboxing gênant
          ProtectSystem = lib.mkForce "off";
          PrivateDevices = lib.mkForce false;
          ProtectHome = lib.mkForce false;
        };
      };
    };
  };
}
