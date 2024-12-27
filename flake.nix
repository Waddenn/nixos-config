{
  description = "NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }:
  {
    nixosConfigurations = {
      asus-nixos = let
        username = "tom";
        hostname = "asus-nixos";
        specialArgs = { inherit inputs username; };
      in nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = specialArgs;
        modules = 
        [
          ./hosts/${hostname}/hardware-configuration.nix
          ./users/${username}/default.nix
          ./modules/templates/laptop.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./home-manager/${username}/home.nix;

            networking.hostName = hostname;

            system.stateVersion = "25.05";
          }
        ];
      };

      # nixos-vm-nextcloud = let
      #   username = "tom";
      #   hostname = "nixos-vm-nextcloud";
      #   specialArgs = { inherit inputs username; };
      # in nixpkgs.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   specialArgs = specialArgs;
      #   modules = 
      #   [
      #     ./hosts/${hostname}/shared/configuration.nix
      #     ./hosts/${hostname}/users/tom.nix
      #     home-manager.nixosModules.home-manager
      #     {
      #       home-manager.useGlobalPkgs = true;
      #       home-manager.useUserPackages = true;
      #       home-manager.users.${username} = import ./home-manager/users/tom.nix;
      #     }
      #   ];
      # };
    };
  };
}
