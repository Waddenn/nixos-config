{ ... }: {
  imports = [
    ../../modules/infra/proxmox-lxc.nix
  ];
  my-services.containers.homeassistant.enable = true;
}
