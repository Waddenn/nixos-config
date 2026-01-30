{ pkgs, ... }: {
  githubRunner.enable = true;
  environment.systemPackages = [
    pkgs.alejandra
  ];
}
