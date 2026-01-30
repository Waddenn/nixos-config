{ ... }: {
  imports = [
    ../../modules/virtualisation/oci-containers/myspeed.nix
  ];
  virtualisation.oci-containers.containers."MySpeed".extraOptions = ["--pull=always"];
}
