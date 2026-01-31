{
  lib,
  inputs,
  nixpkgs,
  home-manager ? null,
}: {
  # Main builder function for generic servers
  mkServer = {
    hostname,
    username ? "nixos",
    system ? "x86_64-linux",
    extraModules ? [],
  }:
    lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs nixpkgs username;
      };
      modules =
        [
          # Auto-import all modules
          ../modules

          # Host configuration
          ../hosts/${hostname}

          # Secrets
          inputs.sops-nix.nixosModules.sops

          # Hostname setup
          {
            networking.hostName = hostname;
          }
        ]
        ++ extraModules;
    };
}
