{
  description = "NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nix-flatpak, sops-nix, ... }:
    let
      lib = nixpkgs.lib;
      mkSystems = import ./lib/mkSystems.nix { inherit inputs nixpkgs home-manager nix-flatpak; };
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
        beszel = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/global.nix
            ./modules/templates/proxmox-lxc.nix
            ./modules/virtualisation/oci-containers/beszel.nix
          {
              tailscale-server.enable = true;
            }
          ];
        }); 
        lxc-test = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/global.nix
            ./modules/templates/proxmox-lxc.nix
            {
              networking.firewall.enable = false;  
            }
          ];
        }); 
      };
    };
}
