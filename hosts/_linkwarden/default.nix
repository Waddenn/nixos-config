{...}: {
  profiles.lxc-base.enable = true;
  virtualisation.oci-containers.containers."linkwarden-linkwarden".extraOptions = ["--pull=always"];
  my-services.containers.linkwarden.enable = true;
}
