{
  config,
  lib,
  ...
}: {
  options.my-services.messaging.gotify.enable = lib.mkEnableOption "Enable gotify";

  config = lib.mkIf config.my-services.messaging.gotify.enable {
    services.gotify.enable = true;
    services.gotify.environment = {
      GOTIFY_SERVER_PORT = 8080;
    };
    networking.firewall.allowedTCPPorts = [8080];
  };
}
