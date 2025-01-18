{ inputs, nixpkgs, home-manager, nix-flatpak }:
let
  lib = nixpkgs.lib;
in
{
  mkDesktopSystem = { hostname, username, ... }:
    {
      system = "x86_64-linux";
      specialArgs = { inherit inputs nixpkgs home-manager nix-flatpak; username = "tom"; };
      modules = [
        ../hosts/${hostname}/hardware-configuration.nix
        ../hosts/${hostname}/configuration.nix
        ../users/${username}/default.nix
        home-manager.nixosModules.home-manager
        nix-flatpak.nixosModules.nix-flatpak
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${username} = import ../home-manager/${username}/home.nix;
          networking.hostName = hostname;
          system.stateVersion = "25.05";
        }
      ];
    };

  mkServerSystem = { modules, extraConfig ? {} }:
    {
      system = "x86_64-linux";
      specialArgs = { inherit inputs nixpkgs home-manager nix-flatpak; username = "nixos"; };
      modules = modules ++ [
        ../users/nixos/default.nix
        {
          system.stateVersion = "25.05";
        }
        extraConfig
      ];
    };
}
