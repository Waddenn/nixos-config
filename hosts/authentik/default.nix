{...}: {
  profiles.lxc-base.enable = true;
  networking.firewall.allowedUDPPorts = [443 80];
  my-services.infra.deployment-target.enable = true;
}
