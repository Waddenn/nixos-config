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

      extraSetFlags = lib.optional config.profiles.tailscale-router.exitNode "--advertise-exit-node";
    };
  };
}
