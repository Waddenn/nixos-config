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
      mkSystems = import ./lib/mkSystems.nix { inherit inputs nixpkgs home-manager nix-flatpak sops-nix; };
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
              ./modules/templates/proxmox-lxc.nix
              { 
                ethtool.enable = true;
              }
            ];
          });

        tailscale-exit-node =
          lib.nixosSystem (mkSystems.mkServerSystem {
            modules = [
              ./modules/templates/proxmox-lxc.nix
              { 
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

        beszel = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/virtualisation/oci-containers/beszel.nix
          ];
        }); 

        adguardhome = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/virtualisation/oci-containers/adguardhome.nix
          {
              systemd.services.systemd-resolved.enable = false;
              networking.nameservers = [ "127.0.0.1" "1.1.1.1" "8.8.8.8" ];
          }
          ];
        }); 

        myspeed = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/virtualisation/oci-containers/myspeed.nix
          ];
        }); 

        terraform = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
          {
              terraform.enable = true;
          }
          ];
        }); 
        
        nextcloud = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/virtualisation/oci-containers/nextcloud.nix
          ];
        }); 

        homeassistant = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/virtualisation/oci-containers/homeassistant.nix
          ];
        }); 

        caddy = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            inputs.sops-nix.nixosModules.sops
          {
              sops.defaultSopsFile = ./secrets/secrets.yaml;
              sops.age.sshKeyPaths = [ "/home/nixos/.ssh/id_ed25519" ];
              sops.secrets.cf_api_token = {};
              caddy.enable = true;
          }
          ];
        }); 

        linkwarden = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/virtualisation/oci-containers/linkwarden.nix
          ];
        }); 

        ansible = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
          {
              ansible.enable = true;
          }
          ];
        }); 

        gotify = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
          {
              gotify.enable = true;
          }
          ];
        }); 

        calibre = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/virtualisation/oci-containers/calibre.nix
          ];
        }); 

        authentik = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
          ];
        }); 
      };
    };
}
