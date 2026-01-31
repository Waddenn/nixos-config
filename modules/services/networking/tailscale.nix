{ config, lib, ... }: {
  options.my-services.networking.tailscale = {
    enable = lib.mkEnableOption "Tailscale Service";
    role = lib.mkOption {
      type = lib.types.enum [ "client" "server" ];
      default = "client";
      description = "Tailscale routing role";
    };
    authKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/run/secrets/tailscale/Client-secret";
      description = "Path to auth key (for client)";
    };
  };

  config = lib.mkIf config.my-services.networking.tailscale.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = config.my-services.networking.tailscale.role;
      # Conditionally set authKeyFile only if client? 
      # Original client used it. Server didn't. 
      # Ideally we use logic here.
      authKeyFile = if config.my-services.networking.tailscale.role == "client" 
                    then config.my-services.networking.tailscale.authKeyFile 
                    else null;
      extraUpFlags = if config.my-services.networking.tailscale.role == "server" 
                     then ["--ssh"] 
                     else [];
    };
  };
}
