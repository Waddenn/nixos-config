{pkgs, ...}: {
  imports = [../../modules/infra/proxmox-lxc.nix];
  my-services.dev.github-runner.enable = true;
  environment.systemPackages = [
    pkgs.alejandra
  ];
}
