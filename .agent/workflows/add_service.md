---
description: Ajouter un nouveau service NixOS respectant l'architecture modulaire
---

Ce workflow t'aide à créer un nouveau service en suivant le pattern "Module" défini dans `ARCHITECTURE.md`.

1. Demander à l'utilisateur le nom du service et sa catégorie (ex: `monitoring`, `security`).
2. Créer le fichier `modules/services/<category>/<nom>.nix`.
3. Insérer le squelette standard :
   ```nix
   { config, lib, pkgs, ... }: {
     options.my-services.<category>.<nom>.enable = lib.mkEnableOption "<Nom du Service>";

     config = lib.mkIf config.my-services.<category>.<nom>.enable {
       # TODO: Implémentation du service
     };
   }
   ```
4. Ajouter l'import de ce nouveau module dans `modules/default.nix` (ou le fichier parent approprié) si nécessaire pour qu'il soit chargé.
5. Proposer à l'utilisateur de l'activer sur un hôte existant.
