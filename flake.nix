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
        modules = [
          ./hosts/${hostname}/configuration.nix
          ./hosts/${hostname}/${username}/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./home-manager/desktop/gnome/${username}/home.nix;
          }
                  ];
      };

      # vm = nixpkgs.lib.nixosSystem {
      #   system = "x86_64-linux"; 
      #   modules = [
      #     ./hosts/vm/configuration.nix
      #   ];
      # };
    };
  };
}
