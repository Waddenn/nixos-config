{ ... }: {
  imports = [
    ../../modules/virtualisation/oci-containers/beszel.nix
  ];
  virtualisation.oci-containers.containers."beszel".extraOptions = ["--pull=always"];
}
