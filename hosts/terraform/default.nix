{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  my-services.programs.terraform.enable = true;
}
