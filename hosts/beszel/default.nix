{...}: {
  imports = [
    ../../modules/infra/proxmox-lxc.nix
  ];
  virtualisation.oci-containers.containers."beszel".extraOptions = ["--pull=always"];
  my-services.containers.beszel.enable = true;
  my-services.infra.deployment-target.enable = true;
}
# Final verification of the internal GitOps flow
