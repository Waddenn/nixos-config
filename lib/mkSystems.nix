{ inputs, nixpkgs, home-manager }:
let
  lib = nixpkgs.lib;
in
{
  mkDesktopSystem = { hostname, username, ... }:
    {
      system = "x86_64-linux";
      specialArgs = { inherit inputs nixpkgs home-manager username; };
      modules = [
        ../hosts/${hostname}/hardware-configuration.nix
        ../hosts/${hostname}/configuration.nix
        ../users/${username}/default.nix
        home-manager.nixosModules.home-manager
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.sops-nix.nixosModules.sops
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${username} = import ../home-manager/${username}/home.nix;
          sops.defaultSopsFile = ../secrets/secrets.yaml;
          sops.age.sshKeyPaths = [ "/home/tom/.ssh/id_ed25519" ];
          networking.hostName = hostname;
          system.stateVersion = "25.05";

        }
      ];
    };

  mkServerSystem = { modules, extraConfig ? {} }:
    {
      system = "x86_64-linux";
      specialArgs = { inherit inputs nixpkgs home-manager; username = "nixos"; };
      modules = modules ++ [
        ../modules/global.nix
        ../users/nixos/default.nix
        ../modules/templates/proxmox-lxc.nix
        ../modules/virtualisation/oci-containers/beszel-agent.nix
        inputs.sops-nix.nixosModules.sops
        {
          system.stateVersion = "25.05";
          python3Minimal.enable = true;
          tailscale-server.enable = true; 
          virtualisation.oci-containers.containers."beszel-agent".extraOptions = [ "--pull=always" ];
        }
        extraConfig
      ];
    };

  mkProxmoxSystem = { hostname, username, ... }:
    {
      system = "x86_64-linux";
      specialArgs = { inherit inputs nixpkgs username; };
      modules = [
        ../hosts/proxmox-vm/hardware-configuration.nix
        ../hosts/proxmox-vm/configuration.nix
        ../users/${username}/default.nix
        inputs.sops-nix.nixosModules.sops
        {
          networking.hostName = hostname;
          system.stateVersion = "25.05";

        }
      ];
    };
    
}
