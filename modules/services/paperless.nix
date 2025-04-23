{
  config,
  lib,
  ...
}: {
  options.paperless.enable = lib.mkEnableOption "Enable paperless";

  config = lib.mkIf config.paperless.enable {
    services.paperless = {
      enable = true;
      address = "0.0.0.0";
      port = 8000;
    };

    networking.firewall.allowedTCPPorts = [8000];
  };
}
