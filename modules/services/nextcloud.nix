{ config, pkgs, ... }:

{
  
  environment.etc."nextcloud-admin-pass".text = "kzjenvkzjen12";
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud28;
    hostName = "localhost";
    config.adminpassFile = "/etc/nextcloud-admin-pass";
  };

}
