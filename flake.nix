{
  description = "NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    alejandra = {
      url = "github:kamadorueda/alejandra/4.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    nix-flatpak,
    sops-nix,
    alejandra,
    ...
  }: let
    lib = nixpkgs.lib;

    mkDesktopSystem = {
      hostname,
      username,
    }: {
      system = "x86_64-linux";
      specialArgs = {inherit inputs nixpkgs home-manager username;};
      modules = [
        ./hosts/${hostname}/hardware-configuration.nix
        ./hosts/${hostname}/configuration.nix
        ./users/${username}/default.nix
        ./users/hypruser/default.nix
        home-manager.nixosModules.home-manager
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.sops-nix.nixosModules.sops
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${username} = import ./home-manager/${username}/home.nix;
          home-manager.users.hypruser = import ./home-manager/hypruser/home.nix;
          networking.hostName = hostname;
          system.stateVersion = "25.05";
        }
      ];
    };

    mkServerSystem = {
      hostname,
      username,
      extraModules ? [],
    }: {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs nixpkgs home-manager username;
      };
      modules =
        [
          ./users/${username}/default.nix
          ./hosts/proxmox-lxc/configuration.nix
          inputs.sops-nix.nixosModules.sops
          {
            networking.hostName = hostname;
          }
        ]
        ++ extraModules;
    };

    mkDesktop = name: username:
      lib.nixosSystem (mkDesktopSystem {
        hostname = name;
        username = username;
      });

    mkServer = name: username: extraModules:
      lib.nixosSystem (mkServerSystem {
        hostname = name;
        username = username;
        extraModules = extraModules;
      });
  in {
    nixosConfigurations = {
      asus-nixos = mkDesktop "asus-nixos" "tom";

      lenovo-nixos = mkDesktop "lenovo-nixos" "tom";

      tailscale-subnet = mkServer "tailscale-subnet" "nixos" [
        {ethtool.enable = true;}
      ];

      tailscale-exit-node = mkServer "tailscale-exit-node" "nixos" [
        {ethtool.enable = true;}
      ];

      uptime-kuma = mkServer "uptime-kuma" "nixos" [
        ./modules/virtualisation/oci-containers/uptime-kuma.nix
      ];

      beszel = mkServer "beszel" "nixos" [
        ./modules/virtualisation/oci-containers/beszel.nix
        {virtualisation.oci-containers.containers."beszel".extraOptions = ["--pull=always"];}
      ];

      adguardhome = mkServer "adguardhome" "nixos" [
        {
          adguardhome.enable = true;
        }
      ];

      myspeed = mkServer "myspeed" "nixos" [
        ./modules/virtualisation/oci-containers/myspeed.nix
        {virtualisation.oci-containers.containers."MySpeed".extraOptions = ["--pull=always"];}
      ];

      terraform = mkServer "terraform" "nixos" [
        {terraform.enable = true;}
      ];

      nextcloud = mkServer "nextcloud" "nixos" [
        ./modules/virtualisation/oci-containers/nextcloud.nix
        {
          virtualisation.oci-containers.containers."mariadb".extraOptions = ["--pull=always"];
          virtualisation.oci-containers.containers."nextcloud".extraOptions = ["--pull=always"];
        }
      ];

      homeassistant = mkServer "homeassistant" "nixos" [
        ./modules/virtualisation/oci-containers/homeassistant.nix
      ];

      caddy = mkServer "caddy" "nixos" [
        {
          sops.defaultSopsFile = ./secrets/secrets.yaml;
          sops.age.sshKeyPaths = ["/home/nixos/.ssh/id_ed25519"];
          caddy.enable = true;
          gitAutoPull.enable = lib.mkForce false;
        }
      ];

      linkwarden = mkServer "linkwarden" "nixos" [
        ./modules/virtualisation/oci-containers/linkwarden.nix
        {virtualisation.oci-containers.containers."linkwarden-linkwarden".extraOptions = ["--pull=always"];}
      ];

      ansible = mkServer "ansible" "nixos" [
        {ansible.enable = true;}
      ];

      gotify = mkServer "gotify" "nixos" [
        {gotify.enable = true;}
      ];

      calibre = mkServer "calibre" "nixos" [
        ./modules/virtualisation/oci-containers/calibre.nix
        {virtualisation.oci-containers.containers."calibre".extraOptions = ["--pull=always"];}
      ];

      authentik = mkServer "authentik" "nixos" [
        {networking.firewall.allowedUDPPorts = [443 80];}
      ];

      grafana = mkServer "grafana" "nixos" [
        {grafana.enable = true;}
      ];

      prometheus = mkServer "prometheus" "nixos" [
        {
          prometheus.enableServer = true;
          prometheus.enableClient = true;
          loki.enable = true;
          promtail.enable = true;
        }
      ];

      gitea = mkServer "gitea" "nixos" [
        {gitea.enable = true;}
      ];

      vaultwarden = mkServer "vaultwarden" "nixos" [
        {
          vaultwarden.enable = true;
        }
      ];

      paperless = mkServer "paperless" "nixos" [
        {
          paperless.enable = true;
        }
      ];

      gitlab = mkServer "gitlab" "nixos" [
        {
          gitlab.enable = true;
        }
      ];

      immich = mkServer "immich" "nixos" [
        {immich.enable = true;}
      ];

      nextcloud-pgsql = mkServer "nextcloud-pgsql" "nixos" [
        {nextcloud.enable = true;}
      ];

      kubernetes = mkServer "kubernetes" "nixos" [];

      onlyoffice = mkServer "onlyoffice" "nixos" [
        {onlyoffice.enable = true;}
      ];

      bourse-dashboard = mkServer "bourse-dashboard" "nixos" [
        {
          networking.firewall.allowedTCPPorts = [5000];
        }
      ];
      gatus = mkServer "gatus" "nixos" [
        {gatus.enable = true;}
      ];

      github-runner = mkServer "github-runner" "nixos" [
        {
          githubRunner.enable = true;
          environment.systemPackages = [
            alejandra.defaultPackage.x86_64-linux
          ];
        }
      ];
      jellyseerr = mkServer "jellyseerr" "nixos" [
        {jellyseerr.enable = true;}
      ];
    };

    checks = lib.genAttrs ["beszel"] (
      name: let
        sys = self.nixosConfigurations.${name}.config.system.build.toplevel;
      in {
        "${name}" = sys;
      }
    );
  };
}
