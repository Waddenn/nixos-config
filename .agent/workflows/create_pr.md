---
description: Publier une modification dans une PR en brouillon, puis valider avant fusion
---

Suivre `AGENTS.md` à la racine du dépôt.

1. Travailler sur une branche `codex/<sujet>`, jamais directement sur `main` par défaut.
2. Vérifier le diff et les tests locaux adaptés, puis pousser la branche.
3. Créer la PR **en brouillon** vers `main` (`gh pr create --draft`). Décrire le problème,
   la correction et les validations réalisées. Ne pas copier de mémoire privée.
4. Continuer les itérations avec les contrôles rapides. Ne pas déclencher de CI complète
   manuellement à chaque push.
5. Quand le travail est terminé, marquer la PR prête (`gh pr ready`) et attendre la CI
   complète. En cas de nombreuses reprises, repasser en brouillon (`gh pr ready --undo`).
6. Fusionner seulement avec la CI complète réussie et l'autorisation de livraison
   appropriée. Attendre ensuite la CI du SHA exact sur `main` avant déploiement.
