{ config, lib, pkgs, ... }:

{
  options.vaultwarden.enable = lib.mkEnableOption "Enable vaultwarden";

  config = lib.mkIf config.vaultwarden.enable {

  services.vaultwarden.enable = true;
  vices.vaultwarden.config = {
      ROCKET_ADDRESS = "0.0.0.0"; 
      ROCKET_PORT = "8222"; 
  }

  };
}
