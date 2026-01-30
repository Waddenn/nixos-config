{ ... }: {
  imports = [
    ../../modules/virtualisation/oci-containers/valheim-server.nix
  ];
  virtualisation.oci-containers.containers."valheim".extraOptions = ["--pull=always"];
}
