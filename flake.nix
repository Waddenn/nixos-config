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
            {
              virtualisation.oci-containers.containers."beszel".extraOptions = [ "--pull=always" ];
            }
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
            {
              virtualisation.oci-containers.containers."MySpeed".extraOptions = [ "--pull=always" ];
            }
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
            {
              virtualisation.oci-containers.containers."mariadb".extraOptions = [ "--pull=always" ];
              virtualisation.oci-containers.containers."nextcloud".extraOptions = [ "--pull=always" ];
            }
          ];
        }); 

        homeassistant = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/virtualisation/oci-containers/homeassistant.nix
          ];
        }); 

        caddy = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
          {
              sops.defaultSopsFile = ./secrets/secrets.yaml;
              sops.age.sshKeyPaths = [ "/home/nixos/.ssh/id_ed25519" ];
              caddy.enable = true;
          }
          ];
        }); 

        linkwarden = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            ./modules/virtualisation/oci-containers/linkwarden.nix
            {
              virtualisation.oci-containers.containers."linkwarden-linkwarden".extraOptions = [ "--pull=always" ];
            }
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
            {
              virtualisation.oci-containers.containers."calibre".extraOptions = [ "--pull=always" ];
            }
          ];
        }); 

        authentik = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            {
              networking.firewall.allowedUDPPorts = [ 443 80 ];
            }
          ];
        }); 

        grafana = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            {
              grafana.enable = true;
            }
          ];
        });

        prometheus = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            {
              prometheus.enable = true;
            }
          ];
        });

        gitea = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            {
              gitea.enable = true;
            }
          ];
        });

        vaultwarden = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            {
              vaultwarden.enable = true;
              networking.firewall.allowedTCPPorts = [ 443 8222 ];
            }
          ];
        });

        paperless = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            {
              paperless.enable = true;
              networking.firewall.allowedTCPPorts = [ 8000 ];
            }
          ];
        });

        gitlab = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            {
              gitlab.enable = true;
              networking.firewall.allowedTCPPorts = [ 443 ];
            }
          ];
        });

        immich = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            {
              immich.enable = true;
            }
          ];
        });

        nextcloud-pgsql = lib.nixosSystem (mkSystems.mkServerSystem {
          modules = [
            {
              nextcloud.enable = true;
            }
          ];
        });
      };
    };
}
