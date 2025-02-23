{ config, lib, pkgs, ... }:

{
  options.vaultwarden.enable = lib.mkEnableOption "Enable Vaultwarden";

  config = lib.mkIf config.vaultwarden.enable {

    services.vaultwarden = {
      enable = true;
      config = {
        ROCKET_ADDRESS = "127.0.0.1";  
        ROCKET_PORT = "8222"; 
      };
    };

  };
}
