{...}: {
  profiles.lxc-base.enable = true;
  networking.firewall.allowedUDPPorts = [443 80];
}
