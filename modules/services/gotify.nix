{ config, lib, ... }:

{
  options.gotify.enable = lib.mkEnableOption "Enable gotify";

  config = lib.mkIf config.gotify.enable {

  services.gotify.enable = true;
  networking.firewall.allowedTCPPorts = [ 80 ];

  };
  
}
