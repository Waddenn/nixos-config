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

    colmena =
      {
        meta = {
          nixpkgs = pkgs;
          specialArgs = {
            inherit inputs;
            username = "nixos";
          };
        };
      }
      // builtins.mapAttrs (name: value: {
        deployment = {
          allowLocalDeployment = name == "dev-nixos";
          targetHost =
            if name == "dev-nixos"
            then null
            else name;
          targetUser = "root";
          tags =
            (
              if name != "dev-nixos"
              then ["remote"]
              else []
            )
            ++ [
              (
                if lib.hasPrefix "adguard" name || lib.hasPrefix "caddy" name
                then "networking"
                else "other"
              )
            ];
        };
        imports = value._module.args.modules;
      })
      self.nixosConfigurations;

    formatter.${system} = pkgs.writeShellApplication {
      name = "nix-fmt";
      runtimeInputs = [pkgs.alejandra];
      text = ''
        alejandra "$@" .
      '';
    };
  };
}
# trigger build Sat Jan 31 10:34:11 PM CET 2026
# trigger build 2 Sat Jan 31 10:36:23 PM CET 2026
# trigger build 3 Sat Jan 31 10:40:01 PM CET 2026
# trigger build 4 Sat Jan 31 10:41:53 PM CET 2026
