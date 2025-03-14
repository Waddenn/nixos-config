{ config, lib, ... }:

{
  options.onlyoffice.enable = lib.mkEnableOption "Enable onlyoffice";

  config = lib.mkIf config.onlyoffice.enable {

  services.onlyoffice = {
    enable = true;
    hostname = "localhost";
  };
  networking.firewall.allowedTCPPorts = [ 8000 ];

  services.caddy = {
  virtualHosts = {
    "office.example.org".extraConfig = ''
      reverse_proxy http://127.0.0.1:8000 {
        # Required to circumvent bug of Onlyoffice loading mixed non-https content
        header_up X-Forwarded-Proto https
      }
    '';
  };
};
  };
}

