---
description: Créer une Pull Request sur GitHub à partir de la branche courante
---

Ce workflow automatise la publication de ton travail.

1.  **Vérifications** :
    *   Vérifier que `nix flake check` passe (via le workflow `/validate` si besoin).
    *   Vérifier que tous les fichiers sont commités.

2.  **Push** :
    *   Pousser la branche courante vers le remote `origin`.

3.  **Création de la PR** :
    *   Utiliser l'outil `create_pull_request` du MCP GitHub.
    *   **Titre** : Générer un titre clair basé sur le dernier commit ou le nom de la branche.
    *   **Body** : Générer une description résumant les changements (en lisant `memory.md` ou les diffs).
    *   **Base** : `main`.
    *   **Head** : La branche courante.

4.  **Confirmation** :
    *   Donner l'URL de la PR à l'utilisateur.
