{...}: {
  profiles.lxc-base.enable = true;
  virtualisation.oci-containers.containers."beszel".extraOptions = ["--pull=always"];
  my-services.monitoring.beszel-server.enable = true;
}
# Final verification of the internal GitOps flow
