{
  config,
  lib,
  ...
}: {
  options.profiles.tailscale-router = {
    enable = lib.mkEnableOption "Tailscale router profile";
    exitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Configure as exit node";
    };
  };

  config = lib.mkIf config.profiles.tailscale-router.enable {
    profiles.lxc-base.enable = true;
    my-services.networking.ethtool.enable = true;
    my-services.networking.tailscale = {
      enable = true;
      role = "server"; # Routers are servers in our context
      
      # If upstream module supported generic extraUpFlags logic properly we could use it
      # For now tailscale module logic handles server flags
    };
    
    # Exit node optimization/config if specific logic exists?
    # Currently tailscale module handles role=server with --ssh
    # If we need --advertise-exit-node it would go here if tailscale module allows it
  };
}
