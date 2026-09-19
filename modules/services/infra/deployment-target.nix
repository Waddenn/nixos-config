{
  lib,
  config,
  ...
}: {
  options.my-services.infra.deployment-target.enable = lib.mkEnableOption "Host is a target for internal deployments";

  config = lib.mkIf config.my-services.infra.deployment-target.enable {
    my-services.infra.pull-updater.enable = lib.mkDefault false;

    # Colmena pushes complete closures from dev-nixos; targets need no Git checkout.
    users.users.root.openssh.authorizedKeys.keys = [
      (import ../../../provisioning/controller-public-key.nix)
    ];
    users.users.nixos.openssh.authorizedKeys.keys = [
      (import ../../../provisioning/controller-public-key.nix)
    ];
  };
}
