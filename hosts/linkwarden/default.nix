{ ... }: {
  imports = [
    ../../modules/virtualisation/oci-containers/linkwarden.nix
  ];
  virtualisation.oci-containers.containers."linkwarden-linkwarden".extraOptions = ["--pull=always"];
}
