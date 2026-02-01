{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  profiles.tailscale-router = {
    enable = true;
    exitNode = true;
  };
}
