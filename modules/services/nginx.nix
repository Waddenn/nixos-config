{config, ...}: {
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
}
