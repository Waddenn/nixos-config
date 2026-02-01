{
  config,
  lib,
  pkgs,
  ...
}: {
  options.my-services.misc.vaultwarden.enable = lib.mkEnableOption "Enable Vaultwarden";

  config = lib.mkIf config.my-services.misc.vaultwarden.enable {
    services.vaultwarden = {
      enable = true;
      config = {
        ROCKET_ADDRESS = "0.0.0.0";
        ROCKET_PORT = "8222";
        SIGNUPS_ALLOWED = false;
        DOMAIN = "https://bitwarden.hexaflare.net";
      };
    };

    networking.firewall.allowedTCPPorts = [443 8222];
  };
}
