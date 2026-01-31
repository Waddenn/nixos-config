{...}: {
  imports = [
    ../../modules/infra/proxmox-lxc.nix
  ];
  virtualisation.oci-containers.containers."valheim".extraOptions = ["--pull=always"];
  my-services.containers.valheim-server.enable = true;
}
