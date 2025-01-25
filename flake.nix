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
              { 
                tailscale-server.enable = true; 
                ethtool.enable = true;
              }
            ];
          });

        tailscale-exit-node =
          lib.nixosSystem (mkSystems.mkServerSystem {
            modules = [
              ./modules/global.nix
              ./modules/templates/proxmox-lxc.nix
              { 
                tailscale-server.enable = true; 
                ethtool.enable = true;
              }
            ];
          });

        uptime-kuma = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/templates/proxmox-lxc.nix
            ./modules/virtualisation/oci-containers/uptime-kuma.nix
          ];
        });

        searxng = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/global.nix
            {
              tailscale-server.enable = true;
              docker.enable = true;
            }
          ];
        }); 
        beszel = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/global.nix
            ./modules/virtualisation/oci-containers/beszel.nix
          {
              tailscale-server.enable = true;
          }
          ];
        }); 

        adguardhome = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/global.nix
            ./modules/virtualisation/oci-containers/adguardhome.nix
          {
              tailscale-server.enable = true;
              systemd.services.systemd-resolved.enable = false;
              networking.nameservers = [ "127.0.0.1" "1.1.1.1" "8.8.8.8" ];
          }
          ];
        }); 

        myspeed = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/global.nix
            ./modules/virtualisation/oci-containers/myspeed.nix
          {
              tailscale-server.enable = true;
          }
          ];
        }); 
      };
    };
}
