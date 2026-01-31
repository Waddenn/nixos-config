{...}: {
  imports = [
    ../../modules/infra/proxmox-lxc.nix
  ];
  virtualisation.oci-containers.containers."MySpeed".extraOptions = ["--pull=always"];
  my-services.containers.myspeed.enable = true;
}
