{lib, ...}: {
  imports = [../../modules/services/infra/opnsense-maintenance.nix];
  my-services.infra.opnsense-maintenance.issuer = true;
  my-services.networking.tailscale.tags = ["tag:managed-server" "tag:caddy"];
  profiles.lxc-base.enable = true;
  my-services.networking.caddy.enable = true;
}
