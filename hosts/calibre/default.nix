{ ... }: {
  imports = [
    ../../modules/virtualisation/oci-containers/calibre.nix
  ];
  virtualisation.oci-containers.containers."calibre".extraOptions = ["--pull=always"];
}
