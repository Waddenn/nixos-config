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

    checks.${system} = lib.mapAttrs (name: host: host.config.system.build.toplevel) self.nixosConfigurations;

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
      // builtins.mapAttrs (name: value: let
        isDeploymentTarget =
          lib.attrByPath ["config" "my-services" "infra" "deployment-target" "enable"] false value;
      in {
        deployment = {
          allowLocalDeployment = name == "dev-nixos";
          tags =
            if name == "dev-nixos"
            then ["local"]
            else lib.optional isDeploymentTarget "remote";
          targetHost =
            if name == "dev-nixos"
            then null
            else name;
          targetUser = "root";
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
