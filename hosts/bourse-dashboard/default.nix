{...}: {
  profiles.lxc-base.enable = true;
  networking.firewall.allowedTCPPorts = [5000];
}
