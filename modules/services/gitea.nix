{ config, lib, pkgs, ... }:

{
  options.gitea.enable = lib.mkEnableOption "Enable gitea"; 

  config = lib.mkIf config.gitea.enable {

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

    domain  = "gitea.example.org";
    rootUrl = "https://gitea.example.org";

    # configureReverseProxy = true; 

    # extraConfig = {
    #   security = {
    #     PASSWORD_COMPLEXITY = "off";
    #   };
    #   # etc.
    # };
  };

  networking.firewall.allowedTCPPorts = [ 3000 ];

  };
}
