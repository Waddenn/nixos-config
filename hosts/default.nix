{
  lib,
  inputs,
  nixpkgs,
  home-manager,
  system,
  ...
}: let
  mkDesktopSystem = {
    hostname,
    username,
  }: {
    inherit system;
    specialArgs = {inherit inputs nixpkgs home-manager username;};
    modules = [
      ./${hostname}/hardware-configuration.nix
      ./${hostname}/configuration.nix
      ../users/${username}/default.nix
      home-manager.nixosModules.home-manager
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.sops-nix.nixosModules.sops
      inputs.stylix.nixosModules.stylix
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;

        home-manager.backupFileExtension = "backup";
        home-manager.extraSpecialArgs = {
          inherit system inputs;
        };
        networking.hostName = hostname;
        system.stateVersion = "25.05";
      }
    ];
  };

  mkServerSystem = {
    hostname,
    username,
  }: {
    inherit system;
    specialArgs = {
      inherit inputs nixpkgs home-manager username;
    };
    modules = [
      ../users/${username}/default.nix
      ./proxmox-lxc/configuration.nix
      ./${hostname}
      inputs.sops-nix.nixosModules.sops
      inputs.stylix.nixosModules.stylix
      {
        networking.hostName = hostname;
      }
    ];
  };

  mkDesktop = name: username:
    lib.nixosSystem (mkDesktopSystem {
      hostname = name;
      username = username;
    });

  mkServer = name: username:
    lib.nixosSystem (mkServerSystem {
      hostname = name;
      username = username;
    });
in {
  asus-nixos = mkDesktop "asus-nixos" "tom";
  lenovo-nixos = mkDesktop "lenovo-nixos" "tom";

  tailscale-subnet = mkServer "tailscale-subnet" "nixos";
  tailscale-exit-node = mkServer "tailscale-exit-node" "nixos";
  uptime-kuma = mkServer "uptime-kuma" "nixos";
  beszel = mkServer "beszel" "nixos";
  adguardhome = mkServer "adguardhome" "nixos";
  myspeed = mkServer "myspeed" "nixos";
  terraform = mkServer "terraform" "nixos";
  nextcloud = mkServer "nextcloud" "nixos";
  homeassistant = mkServer "homeassistant" "nixos";
  caddy = mkServer "caddy" "nixos";
  linkwarden = mkServer "linkwarden" "nixos";
  ansible = mkServer "ansible" "nixos";
  gotify = mkServer "gotify" "nixos";
  calibre = mkServer "calibre" "nixos";
  authentik = mkServer "authentik" "nixos";
  grafana = mkServer "grafana" "nixos";
  prometheus = mkServer "prometheus" "nixos";
  gitea = mkServer "gitea" "nixos";
  vaultwarden = mkServer "vaultwarden" "nixos";
  paperless = mkServer "paperless" "nixos";
  gitlab = mkServer "gitlab" "nixos";
  immich = mkServer "immich" "nixos";
  nextcloud-pgsql = mkServer "nextcloud-pgsql" "nixos";
  kubernetes = mkServer "kubernetes" "nixos";
  dev-nixos = mkServer "dev-nixos" "nixos";
  onlyoffice = mkServer "onlyoffice" "nixos";
  bourse-dashboard = mkServer "bourse-dashboard" "nixos";
  gatus = mkServer "gatus" "nixos";
  github-runner = mkServer "github-runner" "nixos";
  jellyseerr = mkServer "jellyseerr" "nixos";
  glance = mkServer "glance" "nixos";
  valheim = mkServer "valheim" "nixos";
}
