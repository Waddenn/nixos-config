{
  config,
  pkgs,
  lib,
  ...
}: {
  options.my-services.uptime-kuma.enable = lib.mkEnableOption "Uptime Kuma Service";

  config = lib.mkIf config.my-services.uptime-kuma.enable {
    services.uptime-kuma = {
      enable = true;
      package = pkgs.uptime-kuma; # Use native package
      settings = {
        PORT = "3001";
      };
    };

    networking.firewall.allowedTCPPorts = [ 3001 ];
  };
}
