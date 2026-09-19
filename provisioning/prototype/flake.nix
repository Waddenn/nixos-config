{
  description = "Isolated Proxmox LXC experiment; never part of the production fleet";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    terranix.url = "github:terranix/terranix/2.9.0";
    terranix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
    nixpkgs,
    terranix,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.default = terranix.lib.terranixConfiguration {
      inherit system;
      modules = [./config.nix];
    };
    devShells.${system}.default = pkgs.mkShell {
      packages = [pkgs.opentofu pkgs.python3 pkgs.util-linux pkgs.curl pkgs.openssh pkgs.shellcheck];
    };
  };
}
