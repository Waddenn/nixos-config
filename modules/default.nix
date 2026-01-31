{lib, ...}: {
  imports = let
    # Helper to recursively find all .nix files
    files = lib.filesystem.listFilesRecursive ./.;

    # Filter function
    isModule = file: let
      pathStr = toString file;
      name = baseNameOf pathStr;
    in
      lib.hasSuffix ".nix" pathStr
      && name != "default.nix"
      && name != "boot.nix"
      && !lib.hasInfix "modules/infra" pathStr
      && name != "mac-randomize.nix"; # Exclude other known non-modules if any

    modules = builtins.filter isModule files;
  in
    modules;
}
