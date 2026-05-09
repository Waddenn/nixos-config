{...}: {
  profiles.lxc-base.enable = true;
  virtualisation.oci-containers.containers."valheim".extraOptions = ["--pull=always"];
  my-services.containers.valheim-server.enable = true;
}
