{
  description = "NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nix-flatpak, ... }:
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
          ./hosts/${hostname}/configuration.nix
          ./users/${username}/default.nix
          home-manager.nixosModules.home-manager
          nix-flatpak.nixosModules.nix-flatpak
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./home-manager/${username}/home.nix;

            networking.hostName = hostname;
            system.stateVersion = "25.05";
          }
        ];
      };

      uptime-kuma = let
        username = "nixos";
        specialArgs = { inherit inputs username; };
      in nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = specialArgs;
        modules = 
        [
          ./modules/templates/proxmox-lxc.nix
          ./modules/services/docker/uptime-kuma.nix
          ./users/${username}/default.nix
          {
            system.stateVersion = "25.05";
          }
        ];
      };

      adguardhome = let
        username = "nixos";
        specialArgs = { inherit inputs username; };
      in nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = specialArgs;
        modules = 
        [
          ./modules/templates/proxmox-lxc.nix
          ./modules/services/docker/adguardhome.nix
          ./users/${username}/default.nix
          {
            system.stateVersion = "25.05";
          }
        ];
      };

      mullvad-browser = let
        username = "nixos";
        specialArgs = { inherit inputs username; };
      in nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = specialArgs;
        modules = 
        [
          ./modules/templates/proxmox-lxc.nix
          ./modules/services/docker/mullvad-browser.nix
          ./users/${username}/default.nix
          {
            system.stateVersion = "25.05";
          }
        ];
      };
      
    };
  };
}
