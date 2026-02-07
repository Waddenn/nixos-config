{...}: {
  profiles.lxc-base.enable = true;
  virtualisation.oci-containers.containers."calibre".extraOptions = ["--pull=always"];
  my-services.containers.calibre.enable = true;
}
