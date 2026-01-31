# GitOps Trigger: Verification
{...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  jellyseerr.enable = true;
  deploymentTarget.enable = true;
}
