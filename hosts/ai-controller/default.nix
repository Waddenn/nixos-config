{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];

  my-services.ai.infra-agents.enable = true;
}
