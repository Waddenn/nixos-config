{
  description = "NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs = { self, nixpkgs, home-manager, nix-flatpak, ... }:
    let
      lib = nixpkgs.lib;
      mkSystems = import ./lib/mkSystems.nix { inherit nixpkgs home-manager nix-flatpak; };
    in
    {
      nixosConfigurations = {
        asus-nixos =
          lib.nixosSystem (mkSystems.mkDesktopSystem {
            hostname = "asus-nixos";
            username = "tom";
          });

        lenovo-nixos =
          lib.nixosSystem (mkSystems.mkDesktopSystem {
            hostname = "lenovo-nixos";
            username = "tom";
          });

        tailscale-subnet =
          lib.nixosSystem (mkSystems.mkServerSystem {
            modules = [
              ./modules/global.nix
              ./modules/templates/proxmox-lxc.nix
              { tailscale-server.enable = true; }
            ];
          });
                uptime-kuma = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/templates/proxmox-lxc.nix
            ./modules/services/docker/uptime-kuma.nix
          ];
        });

        searxng = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/global.nix
            ./modules/templates/proxmox-lxc.nix
            {
              tailscale-server.enable = true;
              docker.enable = true;
            }
          ];
        });
      };
    }
}
