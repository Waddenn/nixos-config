{ config, lib, ... }:

{
  options.tailscale-server.enable = lib.mkEnableOption "Enable tailscale-server";

  config = lib.mkIf config.tailscale-server.enable {

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
    authKeyFile = "/run/secrets/tailscale/Server-secret";
  };
    sops.secrets."tailscale/Server-secret" = {};
    sops.secrets."tailscale/Server-secret".owner = config.users.tailscale.name;
  };
}
