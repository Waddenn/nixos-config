{...}: {
  imports = [
    ../../modules/infra/proxmox-lxc.nix
  ];
  virtualisation.oci-containers.containers."linkwarden-linkwarden".extraOptions = ["--pull=always"];
  my-services.containers.linkwarden.enable = true;
}
