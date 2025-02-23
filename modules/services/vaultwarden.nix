{ config, lib, pkgs, ... }:

{
  options.vaultwarden.enable = lib.mkEnableOption "Enable Vaultwarden";

  config = lib.mkIf config.vaultwarden.enable {

    services.vaultwarden = {
      enable = true;
      config = {
        ROCKET_ADDRESS = "0.0.0.0";  
        ROCKET_PORT = "8222"; 
        SIGNUPS_ALLOWED = false;
        DOMAIN = "https://bitwarden.hexaflare.net";
        EXPERIMENTAL_CLIENT_FEATURE_FLAGS=extension-refresh;
      };
    };

  };
}
