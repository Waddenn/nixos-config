{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  immich.enable = true;

  # Only allow access from internal network (192.168.40.0/24) where Caddy is located
  # This prevents direct public access to Immich, forcing traffic through Caddy
  networking.firewall = {
    interfaces = {
      # Allow Immich port only on internal interface
      eth0.allowedTCPPorts = [2283];
    };
    # Reject all other interfaces (WAN, etc.)
  };
}
