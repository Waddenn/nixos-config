# Shared verbatim by nixosConfigurations and Colmena.
{
  inputs,
  hostname,
  system,
}: [
  ../modules
  ../hosts/${hostname}
  inputs.sops-nix.nixosModules.sops
  {
    nixpkgs.hostPlatform = system;
    nixpkgs.flake.source = inputs.nixpkgs.outPath;
    networking.hostName = hostname;
  }
]
