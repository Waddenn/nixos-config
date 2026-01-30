{ ... }: {
  imports = [
    ../../modules/virtualisation/oci-containers/nextcloud.nix
  ];
  virtualisation.oci-containers.containers."mariadb".extraOptions = ["--pull=always"];
  virtualisation.oci-containers.containers."nextcloud".extraOptions = ["--pull=always"];
}
