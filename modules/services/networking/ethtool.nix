{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my-services.networking.ethtool;
in {
  options.my-services.networking.ethtool = {
    enable = lib.mkEnableOption "Enable network optimization via ethtool";
    lxcOptimization = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Disable network offloading features for better stability in LXC (Tailscale)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.ethtool];

    # Optimization for LXC / Tailscale performance
    # Disables UDP Segmentation Offload which causes issues on virtualized interfaces
    systemd.services.ethtool-optimization = lib.mkIf cfg.lxcOptimization {
      description = "Ethtool Network Optimization";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.ethtool}/bin/ethtool -K eth0 rx off tx off tso off gso off gro off lro off";
      };
    };
  };
}
