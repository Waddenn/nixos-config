---
description: Vérifier l'état de la CI (GitHub Actions) sur une Pull Request
---

Ce workflow permet de vérifier si les tests passent sur GitHub.

1.  **Identifier la PR** :
    *   Si un numéro est donné, l'utiliser.
    *   Sinon, rechercher la PR associée à la branche courante avec `search_pull_requests`.

2.  **Récupérer le Statut** :
    *   Utiliser l'outil `pull_request_read` avec :
        *   `pullNumber`: <le numéro>
        *   `method`: "get_status"
    
3.  **Analyser la réponse** :
    *   L'outil renverra l'état des "checks" (Succès, Échec, En cours).
    *   Informer l'utilisateur du résultat.
