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
      mkSystems = import ./lib/mkSystems.nix { inherit inputs nixpkgs home-manager; };

      # Factorisation des modules communs serveurs
      commonServerModules = [
        ../modules/global.nix
        ../users/nixos/default.nix
        ../modules/templates/proxmox-lxc.nix
        ../modules/virtualisation/oci-containers/beszel-agent.nix
        inputs.sops-nix.nixosModules.sops
        { system.stateVersion = "25.05"; }
      ];

      mkDesktop = name: username:
        lib.nixosSystem (mkSystems.mkDesktopSystem {
          hostname = name;
          username = username;
        });

      mkServer = name: extraModules:
        lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs nixpkgs home-manager; username = "nixos"; };
          modules = commonServerModules ++ extraModules;
        };

    in {
      nixosConfigurations = {
        asus-nixos = mkDesktop "asus-nixos" "tom";
        lenovo-nixos = mkDesktop "lenovo-nixos" "tom";

        tailscale-subnet = mkServer "tailscale-subnet" [
          { ethtool.enable = true; }
        ];

        tailscale-exit-node = mkServer "tailscale-exit-node" [
          { ethtool.enable = true; }
        ];

        uptime-kuma = mkServer "uptime-kuma" [
          ./modules/virtualisation/oci-containers/uptime-kuma.nix
        ];

        beszel = mkServer "beszel" [
          ./modules/virtualisation/oci-containers/beszel.nix
          { virtualisation.oci-containers.containers."beszel".extraOptions = [ "--pull=always" ]; }
        ];

        adguardhome = mkServer "adguardhome" [
          ./modules/virtualisation/oci-containers/adguardhome.nix
          {
            systemd.services.systemd-resolved.enable = false;
            networking.nameservers = [ "127.0.0.1" "1.1.1.1" "8.8.8.8" ];
          }
        ];

        myspeed = mkServer "myspeed" [
          ./modules/virtualisation/oci-containers/myspeed.nix
          { virtualisation.oci-containers.containers."MySpeed".extraOptions = [ "--pull=always" ]; }
        ];

        terraform = mkServer "terraform" [
          { terraform.enable = true; }
        ];

        nextcloud = mkServer "nextcloud" [
          ./modules/virtualisation/oci-containers/nextcloud.nix
          {
            virtualisation.oci-containers.containers."mariadb".extraOptions = [ "--pull=always" ];
            virtualisation.oci-containers.containers."nextcloud".extraOptions = [ "--pull=always" ];
          }
        ];

        homeassistant = mkServer "homeassistant" [
          ./modules/virtualisation/oci-containers/homeassistant.nix
        ];

        caddy = mkServer "caddy" [
          {
            sops.defaultSopsFile = ./secrets/secrets.yaml;
            sops.age.sshKeyPaths = [ "/home/nixos/.ssh/id_ed25519" ];
            caddy.enable = true;
            prometheus.enableClient = true;
          }
        ];

        linkwarden = mkServer "linkwarden" [
          ./modules/virtualisation/oci-containers/linkwarden.nix
          { virtualisation.oci-containers.containers."linkwarden-linkwarden".extraOptions = [ "--pull=always" ]; }
        ];

        ansible = mkServer "ansible" [
          { ansible.enable = true; }
        ];

        gotify = mkServer "gotify" [
          { gotify.enable = true; }
        ];

        calibre = mkServer "calibre" [
          ./modules/virtualisation/oci-containers/calibre.nix
          { virtualisation.oci-containers.containers."calibre".extraOptions = [ "--pull=always" ]; }
        ];

        authentik = mkServer "authentik" [
          { networking.firewall.allowedUDPPorts = [ 443 80 ]; }
        ];

        grafana = mkServer "grafana" [
          { grafana.enable = true; }
        ];

        prometheus = mkServer "prometheus" [
          { prometheus.enableServer = true; }
        ];

        gitea = mkServer "gitea" [
          { gitea.enable = true; }
        ];

        vaultwarden = mkServer "vaultwarden" [
          {
            vaultwarden.enable = true;
            networking.firewall.allowedTCPPorts = [ 443 8222 ];
          }
        ];

        paperless = mkServer "paperless" [
          {
            paperless.enable = true;
            networking.firewall.allowedTCPPorts = [ 8000 ];
          }
        ];

        gitlab = mkServer "gitlab" [
          {
            gitlab.enable = true;
            networking.firewall.allowedTCPPorts = [ 443 ];
          }
        ];

        immich = mkServer "immich" [
          { immich.enable = true; }
        ];

        nextcloud-pgsql = mkServer "nextcloud-pgsql" [
          { nextcloud.enable = true; }
        ];

        kubernetes = lib.nixosSystem (mkSystems.mkProxmoxSystem {
          hostname = "kubernetes";
          username = "nixos";
        });

        onlyoffice = mkServer "onlyoffice" [
          { onlyoffice.enable = true; }
        ];

        bourse-dashboard = mkServer "bourse-dashboard" [
          {
            networking.firewall.allowedTCPPorts = [ 5000 ];
            programs.tmux.enable = true;
          }
        ];
      };
    };
}
