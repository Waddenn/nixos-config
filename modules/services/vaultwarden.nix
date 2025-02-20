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

    services.caddy = {
      enable = true;
      virtualHosts = {
        "vaultwarden.local" = {
          extraConfig = ''
            reverse_proxy http://127.0.0.1:8222
            tls internal  
          '';
        };
      };
    };

    networking.extraHosts = ''
      127.0.0.1 vaultwarden.local
    '';

  };
}
