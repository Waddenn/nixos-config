{ config, lib, ... }:

{
  options.onlyoffice.enable = lib.mkEnableOption "Enable onlyoffice";

  config = lib.mkIf config.onlyoffice.enable {

  services.onlyoffice = {
    enable = true;
    hostname = "localhost";
  };
  networking.firewall.allowedTCPPorts = [ 8000 ];
  };
}

