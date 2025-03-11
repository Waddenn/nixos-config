# openssl rand -base64 32 | sudo tee /var/lib/nextcloud/admin-pass > /dev/null
# sudo chmod 600 /var/lib/nextcloud/admin-pass
# sudo chown nextcloud:nextcloud /var/lib/nextcloud/admin-pass

{ config, lib, pkgs, ... }:

{
  options.nextcloud.enable = lib.mkEnableOption "Enable nextcloud"; 

  config = lib.mkIf config.nextcloud.enable {

  services.nextcloud = {
    enable = true;
    hostName = "nextcloud.hexaflare.net";
    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      adminpassFile = "/var/lib/nextcloud/admin-pass";
    };
    phpOptions = {
        "opcache.interned_strings_buffer" = "16"; 
    };

  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  };
}
