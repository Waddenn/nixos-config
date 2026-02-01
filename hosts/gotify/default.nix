{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  my-services.messaging.gotify.enable = true;
}
