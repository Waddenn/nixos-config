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
      asus-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/asus-nixos/configuration.nix
        ];
      };

      # # Second hôte
      # macbook-nixos = nixpkgs.lib.nixosSystem {
      #   system = "x86_64-darwin"; # ou x86_64-linux si c’est un Linux 
      #   modules = [
      #     ./hosts/macbook-nixos/configuration.nix
      #   ];
      # };
    };
  };
}
