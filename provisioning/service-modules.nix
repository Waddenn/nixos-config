# Same service modules for initial pilots and the main GitOps hive.
{
  service,
  system,
  sopsModule,
  bootstrapKey,
  nixpkgsSource,
  extraModules ? [],
}:
[
  sopsModule
  ./pilot.nix
  service.application.module
  ({lib, ...}: {
    _module.args = {inherit service;};
    nixpkgs.hostPlatform = system;
    nixpkgs.flake.source = nixpkgsSource;
    users.users.root.openssh.authorizedKeys.keys = [
      bootstrapKey
      (import ./controller-public-key.nix)
    ];
    # Keep the transport alive during Colmena switch; fleet.py refreshes it later.
    systemd.services.tailscaled.stopIfChanged = false;
    systemd.services.tailscaled.restartIfChanged = false;
  })
]
++ extraModules
