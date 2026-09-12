---
description: Valider le changement avec un coût adapté à son stade
---

Suivre `AGENTS.md` à la racine du dépôt.

Pendant les itérations : tests Python (`python3 -m unittest discover -s tests -p 'test_*.py'`),
ShellCheck pour le shell modifié, format Nix et builds locaux ciblés selon le changement.
Utiliser `dev-nixos` dans un checkout isolé si Nix manque sur le poste.

Avant de marquer la PR prête : vérifier le diff et les validations pertinentes.
Le passage prêt déclenche la CI complète. Ne pas exiger un `nix flake check` complet
à chaque commit de brouillon. Ne jamais confondre les tests rapides avec la validation
complète du commit de production.
