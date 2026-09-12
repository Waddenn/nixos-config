---
trigger: always_on
description: Règles architecturales et conventions DevOps pour le projet NixOS
---

# Règles Project NixOS

Lire `AGENTS.md` à la racine pour la procédure de branches, PR en brouillon,
validation et déploiement. Ces consignes s'appliquent à chaque tâche.

Tu es un expert NixOS travaillant sur ce dépôt de configuration. Tu DOIS suivre ces règles strictes pour maintenir la philosophie "Explicit Infra, Implicit Services".

## 🏗 Architecture & Patterns

1.  **Philosophie** :
    *   **Explicit Infra** : Tout ce qui concerne le hardware ou la base système (LXC, VM) doit être importé explicitement dans `hosts/<name>/default.nix`.
    *   **Implicit Services** : Les services s'activent UNIQUEMENT via `enable = true` (ex: `my-services.xxx.enable`). JAMAIS d'import de module de service directement dans un host.

2.  **Création de Service (Modules)** :
    *   Chaque nouveau service doit être un fichier dans `modules/services/<category>/<name>.nix`.
    *   Il DOIT exposer une `option` avec `lib.mkEnableOption`.
    *   La configuration doit être wrappée dans `config = lib.mkIf config.my-services.<name>.enable { ... };`.

3.  **Hôtes** :
    *   Les fichiers `hosts/*/default.nix` ne doivent contenir QUE de la configuration (valeurs).
    *   Pas de logique complexe (`let ... in`) dans les hôtes si possible.

## 🧠 Gestion de la Mémoire

1.  **Mise à jour Systématique** : À la fin de chaque tâche significative (décision d'architecture, ajout de feature majeure), l'agent DOIT mettre à jour `.agent/memory.md`.
2.  **Format** : Ajouter une entrée datée dans "Décisions Actées" ou mettre à jour les "Préférences".

## 🛠 Qualité & DevOps

1.  **Formatage** : Toujours lancer `nix fmt` (ou `just fmt` si dispo) après avoir modifié un fichier .nix.

