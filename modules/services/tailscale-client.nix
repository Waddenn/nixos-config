{ config, lib, ... }:

{

  options.tailscale-client.enable = lib.mkEnableOption "Enable tailscale-client";

  config = lib.mkIf config.tailscale-client.enable {

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
    authKeyFile = "/run/secrets/tailscale/Client-secret";
  };
    sops.secrets."tailscale/Client-secret" = {};

  };
}



  