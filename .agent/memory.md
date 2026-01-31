# Mémoire du Projet

## Préférences Utilisateur
- **Philosophie DevOps** : L'utilisateur apprécie l'automatisation, la CI/CD et les workflows structurés.
- **Documentation** : L'utilisateur souhaite que le projet soit "auto-documenté" et facile à comprendre pour une IA.

## Décisions Actées
- [2026-01-31] Adoption de `alejandra` pour le formatage automatique.
- [2026-01-31] Mise en place de GitHub Actions pour la validation.
- [2026-01-31] Structuration de l'agent via `.agent/` (`rules/`, `workflows/`, `context.md`).
- [2026-01-31] Refus des imports implicites de services dans les hôtes.
- [2026-01-31] Intégration complète du MCP GitHub (Issues, PRs, Status, Search).
- [2026-01-31] Création des workflows standards : `/start_task`, `/create_pr`, `/ci_status`.
- [2026-01-31] Résolution en urgence de 5 erreurs de configuration héritées (conflict Nginx, Stylix manquant, options obsolètes, structure des checks).

- [2026-01-31] Réparation du service GitOps (`internal-gitops`) sur `dev-nixos` : correction du PATH pour inclure `sudo` (/run/wrappers/bin) et confirmation de l'automatisation via Colmena.
