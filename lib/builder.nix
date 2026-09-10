{
  lib,
  inputs,
  nixpkgs,
}: {
  mkServer = {
    hostname,
    username ? "nixos",
    system ? "x86_64-linux",
    extraModules ? [],
  }:
    lib.nixosSystem {
      specialArgs = {inherit inputs nixpkgs username;};
      modules = (import ./host-modules.nix {inherit inputs hostname system;}) ++ extraModules;
    };
}
