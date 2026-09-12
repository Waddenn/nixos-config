# Procédure de travail des agents

Ces consignes s'appliquent à tout le dépôt. Respecter les demandes explicites de
l'utilisateur et préserver ses modifications existantes.

## Branches et coût de la CI

- Créer une branche courte `codex/<sujet>` par modification depuis `main` à jour.
  Ne pas développer ni pousser directement sur `main`, sauf demande explicite.
- Pendant les itérations, exécuter les tests ciblés localement et utiliser une PR
  **en brouillon** si le travail est publié. Ne pas ouvrir une PR prête trop tôt.
- Les pushes de branche et les PR en brouillon exécutent seulement les contrôles
  rapides (tests Python, ShellCheck, whitespace). Aucun build Nix sur GitHub.
- Quand le changement est terminé, vérifier le diff, lancer les validations locales
  pertinentes, puis marquer la PR prête (`gh pr ready`). Cela déclenche la CI complète.
  Les nouveaux pushes sur une PR prête relancent la CI complète : pour reprendre de
  nombreuses itérations, repasser d'abord la PR en brouillon (`gh pr ready --undo`).
- `workflow_dispatch` lance volontairement la CI complète ; ne pas l'utiliser pour
  chaque essai. Ne pas ajouter `[skip ci]` pour contourner les contrôles.
- Après fusion, attendre la CI réussie du commit exact de `main` avant déploiement.
  Une CI verte de branche ou de brouillon ne valide jamais un déploiement.
- Ne pas fusionner une PR dont la CI complète échoue ou est annulée. Une autorisation
  explicite existante de livrer/déployer peut couvrir la fusion ; sinon laisser la PR
  prête et donner son lien. Ne pas redemander une autorisation déjà fournie.

## Validation et déploiement

- Tests rapides : `python3 -m unittest discover -s tests -p 'test_*.py'`.
- Format Nix : `nix fmt -- --check`. Utiliser un checkout isolé sur `dev-nixos`
  si Nix n'est pas disponible sur le poste. Ne pas écraser son checkout de travail.
- Choisir les builds Nix locaux adaptés au changement ; ne pas reconstruire toute
  la flotte pour chaque petite itération. La CI complète vérifie NixOS/Colmena et
  sélectionne les systèmes affectés. Les changements globaux gardent le parcours complet.
- `dev-nixos` reste le seul contrôleur. Garder la garde CI sur le SHA exact, les
  canaris, les contrôles de santé et d'espace, et le déploiement des seules générations
  en dérive. Ne pas déplacer la CI complète hors GitHub sans demande de l'utilisateur.
- Pour lancer un déploiement autorisé :
  `ssh root@dev-nixos 'systemctl start --no-block internal-gitops.service'`.
- Vérifier `last-run.json`, les générations et la santé réelle après activation.
  Un service systemd `failed` avec des hôtes injoignables peut être un déploiement
  partiel : préciser les hôtes conformes et ceux non vérifiés, sans annoncer un succès total.

## Beszel

- Inventaire NixOS automatique ; seules les machines externes sont saisies dans
  `modules/data/beszel-hosts.nix`. Les dossiers `hosts/_...` sont exclus ; une machine
  simplement hors ligne reste déclarée.
- Conserver les identités et l'historique lors des changements d'inventaire.
- Le serveur et les agents NixOS partagent `lib/beszel-release.json`. Ne pas réintroduire
  une image `latest` indépendante ni utiliser `pkgs.beszel` pour ces agents.
- Voir `docs/operations.md` pour les procédures de reprise et les détails opérationnels.
