{
  config,
  lib,
  pkgs,
  ...
}: {
  options.my-services.dev.gitea.enable = lib.mkEnableOption "Enable gitea";

  config = lib.mkIf config.my-services.dev.gitea.enable {
    services.gitea = {
      enable = true;
      package = pkgs.gitea;

      user = "gitea";
      group = "gitea";

      stateDir = "/var/lib/gitea";

      database = {
        type = "sqlite3";
        path = "${config.services.gitea.stateDir}/gitea.db";
      };

      settings = {
        server = {
          DOMAIN = "gitea.hexaflare.net";
          ROOT_URL = "https://gitea.hexaflare.net";
        };
      };

      # configureReverseProxy = true;

      # extraConfig = {
      #   security = {
      #     PASSWORD_COMPLEXITY = "off";
      #   };
      #   # etc.
      # };
    };

    networking.firewall.allowedTCPPorts = [3000];
  };
}
