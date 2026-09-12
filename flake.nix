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
    fleetPolicy = import ./lib/fleet-policy.nix;
  in {
    nixosConfigurations = import ./hosts {
      inherit lib inputs nixpkgs system;
    };

    fleet =
      lib.mapAttrs (name: host: let
        policy = fleetPolicy.${name} or {};
      in {
        target = host.config.my-services.infra.deployment-target.enable;
        local = name == "dev-nixos";
        oci = host.config.virtualisation.oci-containers.containers != {};
        canary = policy.canary or false;
        units = ["tailscaled.service"] ++ lib.optional host.config.my-services.monitoring.beszel-agent.enable "beszel-agent.service" ++ (policy.units or []);
        urls = policy.urls or [];
        expected = toString host.config.system.build.toplevel;
      })
      self.nixosConfigurations;

    checks.${system} =
      lib.mapAttrs (name: host: host.config.system.build.toplevel) self.nixosConfigurations
      // {
        beszel-agent = pkgs.callPackage ./pkgs/beszel-agent.nix {};
        fleet-inventory = assert lib.assertMsg (lib.all (
          name:
            lib.all (unit:
              builtins.hasAttr (lib.removeSuffix ".service" unit)
              self.nixosConfigurations.${name}.config.systemd.services)
            self.fleet.${name}.units
        ) (builtins.attrNames self.fleet)) "Fleet health checks reference an undefined systemd service";
          pkgs.runCommand "fleet-inventory-check" {} "touch $out";
        nextcloud-major-upgrade-policy = let
          host = self.nixosConfigurations.nextcloud-pgsql;
          nextcloud = host.config.services.nextcloud;
          backup = host.config.services.postgresqlBackup;
          healthUrls = self.fleet.nextcloud-pgsql.urls;
        in
          assert lib.assertMsg (lib.versions.major nextcloud.package.version == "33")
          "Nextcloud must stay on major 33 until its migration is validated";
          assert lib.assertMsg (backup.enable && backup.databases == ["nextcloud"])
          "Nextcloud migration requires a declared PostgreSQL backup";
          assert lib.assertMsg (lib.elem "http://192.168.40.116/status.php" healthUrls)
          "Nextcloud fleet health must probe status.php";
            pkgs.runCommand "nextcloud-major-upgrade-policy-check" {} "touch $out";
        deployment-scripts =
          pkgs.runCommand "deployment-scripts-check" {
            nativeBuildInputs = [pkgs.shellcheck pkgs.python3];
          } ''
            shellcheck \
              ${./scripts/deploy-fleet.sh} \
              ${./scripts/fleet-status.sh} \
              ${./scripts/pull-update-host.sh} \
              ${./scripts/update-caddy-plugin-hash.sh}
            export PYTHONDONTWRITEBYTECODE=1
            FLEET_SCRIPT=${./scripts/fleet.py} python3 ${./tests/test_fleet.py}
            CI_PLAN_SCRIPT=${./scripts/plan-ci.py} python3 ${./tests/test_ci_plan.py}
            BESZEL_UPDATER=${./scripts/update-beszel.py} python3 ${./tests/test_beszel_release.py}
            touch "$out"
          '';
      };

    colmena =
      {
        meta = {
          nixpkgs = pkgs;
          specialArgs = {
            inherit inputs nixpkgs lib;
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
            else (lib.optional isDeploymentTarget "remote") ++ lib.optional ((fleetPolicy.${name} or {}).canary or false) "canary";
          targetHost =
            if name == "dev-nixos"
            then null
            else name;
          targetUser = "root";
        };
        imports = import ./lib/host-modules.nix {
          inherit inputs system;
          hostname = name;
        };
      })
      self.nixosConfigurations;

    packages.${system}.colmena = inputs.colmena.packages.${system}.colmena;

    formatter.${system} = pkgs.writeShellApplication {
      name = "nix-fmt";
      runtimeInputs = [pkgs.alejandra];
      text = ''
        alejandra "$@" .
      '';
    };
  };
}
