---
description: Démarrer une feature à partir d'une issue GitHub (Branche + Contexte)
---

Ce workflow automatise le début de travail sur une tâche précise référencée sur GitHub.

1.  **Récupérer l'Issue** : Demande le numéro de l'issue GitHub.
2.  **Lire le contenu** : Utilise l'outil `issue_read` du MCP GitHub pour récupérer le titre et la description.
3.  **Créer la branche** : Crée une branche git locale `feat/<issue-id>-<titre-sanitized>` (ou `fix/...` selon les labels).
4.  **Initialiser** : Affiche un résumé de la tâche à accomplir pour l'agent.

*Exemple d'usage*:
`Agent, lance le workflow start_task pour l'issue #12`
