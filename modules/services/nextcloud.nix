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
    configureRedis = true;
    config = {
      dbtype = "pgsql";
      adminpassFile = "/var/lib/nextcloud/admin-pass";
    };

    settings = {
      log_type = "file";
      default_phone_region = "FR";
      maintenance_window_start = 1;  
      overwriteprotocol = "https";
      trusted_proxies = [ "192.168.40.105" ];
      trusted_domains = [ "192.168.40.116"];
    };

    phpOptions = {
        "opcache.interned_strings_buffer" = "16"; 
    };

    appstoreEnable = true;

    extraAppsEnable = true;
    extraApps = with config.services.nextcloud.package.packages.apps; {
      inherit
        calendar
        contacts
        notes
        onlyoffice
        tasks
        ;
    };

  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  };
}
