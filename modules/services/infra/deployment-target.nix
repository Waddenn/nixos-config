{
  lib,
  config,
  ...
}: {
  options.deploymentTarget.enable = lib.mkEnableOption "Host is a target for internal deployments";

  config = lib.mkIf config.deploymentTarget.enable {
    # Authorize dev-nixos to connect as root and nixos
    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIZu1aXoiBIUuhiSi5S6EjPrtNd/UYh6pZwuH6NGjze nixos@dev-nixos"
    ];
    users.users.nixos.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIZu1aXoiBIUuhiSi5S6EjPrtNd/UYh6pZwuH6NGjze nixos@dev-nixos"
    ];
  };
}
