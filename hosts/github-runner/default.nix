{pkgs, ...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  githubRunner.enable = true;
  environment.systemPackages = [
    pkgs.alejandra
  ];
}
