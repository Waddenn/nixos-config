{
  config,
  lib,
  ...
}: {
  options.my-services.networking.nginx.enable = lib.mkEnableOption "Nginx service";

  config = lib.mkIf config.my-services.networking.nginx.enable {
    services.nginx.enable = true;
    services.nginx.virtualHosts."myhost.org" = {
      addSSL = true;
      enableACME = true;
      root = "/var/www/myhost.org";
    };
    security.acme = {
      acceptTerms = true;
      defaults.email = "foo@bar.com";
    };
  };
}
