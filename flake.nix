{
  description = "NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    colmena = {
      url = "github:zhaofengli/colmena/v0.4.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    lib = nixpkgs.lib;
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    nixosConfigurations = import ./hosts {
      inherit lib inputs nixpkgs system;
    };

    checks.${system} = lib.genAttrs ["beszel"] (
      name: self.nixosConfigurations.${name}.config.system.build.toplevel
    );

    colmena = let
      # Sanitize inputs to avoid circularity (self) and reduce JSON size
      # This prevents the "invalid response" error in Colmena 0.5
      safeInputs = builtins.removeAttrs inputs ["self"];
      
      meta = {
        nixpkgs = pkgs;
        specialArgs = {
          inputs = safeInputs;
          username = "nixos";
        };
      };
    in {
      __schema = "v0.5";
      inherit meta;
      # Colmena 0.5 specifically looks for metaConfig
      metaConfig = meta;
    } // builtins.mapAttrs (name: value: {
      deployment = {
        targetHost = name;
        targetUser = "root";
        tags = [(if lib.hasPrefix "adguard" name || lib.hasPrefix "caddy" name then "networking" else "other")];
      };
      imports = value._module.args.modules;
    }) self.nixosConfigurations;

    colmenaHive = self.colmena;

    apps.${system} = {
      colmena = inputs.colmena.apps.${system}.colmena;
      default = self.apps.${system}.colmena;
    };

    formatter.${system} = pkgs.writeShellApplication {
      name = "nix-fmt";
      runtimeInputs = [pkgs.alejandra];
      text = ''
        alejandra "$@" .
      '';
    };
  };
}
