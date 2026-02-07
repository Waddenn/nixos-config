{...}: {
  profiles.lxc-base.enable = true;
  profiles.tailscale-router = {
    enable = true;
    exitNode = true;
  };
}
