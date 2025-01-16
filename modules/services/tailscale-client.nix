{ config, lib, ... }:

{
  options.tailscale-client.enable = lib.mkEnableOption "Enable tailscale-client";

  config = lib.mkIf config.tailscale-client.enable {

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
  };

  };
}



  