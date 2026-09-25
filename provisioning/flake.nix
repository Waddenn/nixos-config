{
  description = "Declared services: Proxmox ownership and isolated NixOS pilot hive";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    terranix.url = "github:terranix/terranix/2.9.0";
    terranix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    colmena.url = "github:zhaofengli/colmena/v0.4.0";
    colmena.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
    self,
    nixpkgs,
    terranix,
    sops-nix,
    colmena,
    ...
  }: let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    pkgs = nixpkgs.legacyPackages.${system};
    inventory = import ./inventory.nix {inherit lib;};
    active = lib.filterAttrs (_: s: s.lifecycle == "active" && !s.gitops.enable) inventory;
    runtime =
      if builtins.pathExists ./runtime-public.json
      then builtins.fromJSON (builtins.readFile ./runtime-public.json)
      else {};
    pilotModules = name: service:
      import ./service-modules.nix {
        inherit service system;
        sopsModule = sops-nix.nixosModules.sops;
        nixpkgsSource = nixpkgs.outPath;
        bootstrapKey = assert lib.assertMsg (builtins.hasAttr name runtime) "Run discover before building a pilot"; runtime.${name}.sshPublicKey;
      };
  in {
    manifest =
      lib.mapAttrs (name: s: {
        inherit name;
        inherit
          (s)
          environment
          hostname
          vmId
          node
          storage
          cores
          memoryMiB
          diskGiB
          bridge
          ipv4
          lifecycle
          gitops
          resourceAddress
          sshAlias
          tailscaleTags
          monitoring
          ;
        inherit (s.application) port healthPath units healthBody conditions generatedSecrets;
        secretProbe = s.application.secretProbe or null;
      })
      inventory;
    checks.${system}.single-declaration = let
      tf = (import ./terraform.nix {inherit lib;}).resource.proxmox_virtual_environment_container;
      raw = import ./services.nix;
      first = builtins.head (builtins.attrNames raw);
      duplicated = builtins.tryEval (builtins.deepSeq (import ./inventory.nix {
          inherit lib;
          services = raw // {duplicate = raw.${first};};
        })
        true);
    in
      assert !duplicated.success;
      assert lib.all (
        name:
          tf.${name}.vm_id
          == inventory.${name}.vmId
          && tf.${name}.node_name == inventory.${name}.node
          && tf.${name}.initialization.hostname == inventory.${name}.hostname
      ) (builtins.attrNames inventory);
      assert lib.all (
        name:
          self.nixosConfigurations.${name}.config.networking.hostName
          == inventory.${name}.hostname
          && (!inventory.${name}.monitoring
            || self.nixosConfigurations.${name}.config.services.gatus.settings.endpoints
            == lib.optional inventory.${name}.monitoring {
              name = name;
              group = "pilot";
              url = "http://127.0.0.1:${toString inventory.${name}.application.port}${inventory.${name}.application.healthPath}";
              interval = "5s";
              conditions = inventory.${name}.application.conditions;
            })
      ) (builtins.attrNames active);
        pkgs.runCommand "service-inventory-check" {} "touch $out";
    packages.${system} = {
      default = terranix.lib.terranixConfiguration {
        inherit system;
        modules = [./terraform.nix];
      };
      colmena = colmena.packages.${system}.colmena;
    };
    colmena =
      {meta.nixpkgs = pkgs;}
      // lib.mapAttrs (name: service: {
        imports = pilotModules name service;
        deployment = {
          targetHost = service.sshAlias;
          targetUser = "root";
          tags = ["isolated-pilot"];
        };
      })
      active;
    nixosConfigurations = lib.mapAttrs (name: service:
      lib.nixosSystem {
        inherit system;
        modules = pilotModules name service;
      })
    active;
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        pkgs.opentofu
        pkgs.python3
        pkgs.util-linux
        pkgs.curl
        pkgs.openssh
        pkgs.shellcheck
        pkgs.sops
        pkgs.age
        pkgs.ssh-to-age
        colmena.packages.${system}.colmena
      ];
    };
  };
}
