{ ... }: {
  imports = [
    ../../modules/infra/proxmox-lxc.nix
  ];
  virtualisation.oci-containers.containers."calibre".extraOptions = ["--pull=always"];
  my-services.containers.calibre.enable = true;
}
