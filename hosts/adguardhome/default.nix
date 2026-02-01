{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  my-services.networking.adguardhome.enable = true;
}
