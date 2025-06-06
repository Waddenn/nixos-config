{
  config,
  lib,
  ...
}: {
  options.onlyoffice.enable = lib.mkEnableOption "Enable onlyoffice";

  config = lib.mkIf config.onlyoffice.enable {
    services.onlyoffice = {
      enable = true;
    };
    networking.firewall.allowedTCPPorts = [8000];
  };
}
