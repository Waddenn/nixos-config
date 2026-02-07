{pkgs, ...}: {
  profiles.lxc-base.enable = true;
  my-services.dev.github-runner.enable = true;
  environment.systemPackages = [
    pkgs.alejandra
  ];
}
