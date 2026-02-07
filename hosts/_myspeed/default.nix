{...}: {
  profiles.lxc-base.enable = true;
  virtualisation.oci-containers.containers."MySpeed".extraOptions = ["--pull=always"];
  my-services.containers.myspeed.enable = true;
}
