{ config, lib, ... }:

let
  # Fonction pour parcourir tous les fichiers .nix dans le dossier et ses sous-dossiers
  loadModules = dir: lib.filterAttrs (_: path:
    builtins.match ".*\\.nix$" (builtins.baseNameOf path) != null
  ) (lib.attrNamesToAttrs (builtins.readDir dir)) // lib.concatMapAttrs (name: attrs:
    if attrs.type == "directory" then
      loadModules "${dir}/${name}"
    else
      {}
  ) (builtins.readDir dir);

  # Liste des modules trouvés (clé = nom, valeur = chemin)
  allModules = loadModules ../../modules;

  # Liste des modules activés (par défaut false si non précisé dans configuration.nix)
  enabledModules = lib.filterAttrs (name: _path:
    builtins.getAttr name config.modules.enableModules or false
  ) allModules;
in
{
  # Ajoutez les modules activés à imports
  imports = builtins.attrValues enabledModules;

  options.modules.enableModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.bool;
    default = {}; # Tous les modules sont false par défaut
    description = ''
      Control which modules are enabled. Set the value to `true` to enable a specific module, or `false` to disable it.
      Detected modules: ${builtins.concatStringsSep ", " (builtins.attrNames allModules)}
    '';
  };
}
