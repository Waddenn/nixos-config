{
  lib,
  inputs,
  nixpkgs,
  system,
  ...
}: let
  builder = import ../lib/builder.nix {
    inherit lib inputs nixpkgs;
  };

  # Auto-discovery logic
  entries = builtins.readDir ./.;
  # validAndDirectories = name: type: type == "directory"; # Simple filter

  hostNames = lib.attrNames (lib.filterAttrs (n: v: v == "directory" && !(lib.hasPrefix "_" n)) entries);

  configGen = name:
    builder.mkServer {
      hostname = name;
      username = "nixos";
    };
in
  lib.genAttrs hostNames configGen
# Final test rollout

