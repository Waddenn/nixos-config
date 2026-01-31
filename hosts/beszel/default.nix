{...}: {
  imports = [
    ../../modules/infra/proxmox-lxc.nix
  ];
  virtualisation.oci-containers.containers."beszel".extraOptions = ["--pull=always"];
  my-services.containers.beszel.enable = true;
  autoUpgrade.enable = true;
}
