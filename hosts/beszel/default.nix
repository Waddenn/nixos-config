{...}: {
  imports = [
    ../../modules/infra/proxmox-lxc.nix
  ];
  virtualisation.oci-containers.containers."beszel".extraOptions = ["--pull=always"];
  my-services.monitoring.beszel-server.enable = true;
  my-services.infra.deployment-target.enable = true;
}
# Final verification of the internal GitOps flow

