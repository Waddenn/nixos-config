{
  description = "NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    alejandra = {
      url = "github:kamadorueda/alejandra/3.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    alejandra,
    ...
  }: let
    lib = nixpkgs.lib;
    system = "x86_64-linux";
  in {
    nixosConfigurations = import ./hosts {
      inherit lib inputs nixpkgs system;
    };

    checks.${system} = lib.genAttrs ["beszel"] (
      name: self.nixosConfigurations.${name}.config.system.build.toplevel
    );

    formatter.x86_64-linux = alejandra.defaultPackage.x86_64-linux;
  };
}
