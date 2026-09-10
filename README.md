# Infrastructure NixOS / Proxmox

20 hôtes déclarés dans `hosts/`, avec secrets SOPS, images OCI figées par digest
et déploiement automatique depuis `dev-nixos`.

## Déploiement

Le timer `internal-gitops` réconcilie la flotte toutes les heures. Il :

1. récupère `origin/main` et exige une CI `push` ou `workflow_dispatch` réussie sur `main` pour ce SHA exact ;
2. ouvre un checkout temporaire de cette révision, sans écraser le checkout de travail ;
3. vérifie l'accès aux cibles ; un canari inaccessible bloque le déploiement ;
4. construit les hôtes joignables et le contrôleur avec Colmena avant toute activation ;
5. active les canaris séquentiellement, puis vérifie génération active, profil et santé ;
6. active les autres hôtes avec au maximum trois déploiements simultanés ;
7. met à jour le contrôleur en dernier, uniquement si toutes les cibles sont conformes.

Les hôtes indisponibles hors canaris sont retentés au prochain passage. Une activation
interdite par NixOS prépare la génération de boot et signale `reboot-required`, sans
redémarrage automatique. Une erreur applicative bloque la suite ; elle ne déclenche
pas de rollback aveugle d'une base de données.

Colmena construit et transfère les systèmes. `scripts/fleet.py` ne conserve que la
politique de déploiement, les contrôles et les notifications. Les cibles n'ont plus
besoin de dépôt Git ni d'agent pull. L'agent historique reste exclusivement sur
`dev-nixos` pour son bootstrap et sa mise à jour locale dans une unité systemd séparée.

## Commandes

| Commande | Fonction |
| --- | --- |
| `just validate` | Évaluation, construction des checks et des configurations |
| `just test` | Tests de la politique de déploiement, sans accès aux machines |
| `just check-colmena` | Vérifie l'égalité des générations NixOS et Colmena |
| `just fmt` | Formatage Nix |
| `just update` | Mise à jour des inputs et des digests OCI, à revoir avant fusion |
| `just deploy` / `just reconcile` | Réconciliation via le contrôleur, avec garde CI obligatoire |
| `just fleet-status` | Compare la flotte au checkout local, sans fetch ni activation |
| `just deploy-watch` | Journaux du contrôleur |

`just fleet-status` fonctionne aussi depuis Bluefin avec la Distrobox `nix-deploy`.
Il ne se fie ni au checkout Git des cibles ni à l'état enregistré par l'ancien agent.

Le dernier résultat se trouve sur le contrôleur dans
`/var/lib/internal-gitops/last-run.json`. Un verrou empêche les déploiements concurrents.
Les notifications Discord identiques sont dédupliquées ; aucune notification n'est
émise par les tests locaux.

## Organisation et maintenance

- `lib/host-modules.nix` : modules identiques pour NixOS et Colmena.
- `lib/fleet-policy.nix` : canaris, unités systemd et sondes HTTP attendues.
- `lib/container-images.json` : références des images et digests vérifiés auprès des registres.
- `modules/default.nix` : imports explicites ; un nouveau fichier n'est pas activé implicitement.
- `hosts/` : chaque répertoire sans préfixe `_` définit un hôte actif.

La CI teste les scénarios de panne, vérifie les noms des unités surveillées,
compare les générations Colmena/NixOS et construit chaque système. La PR hebdomadaire
actualise les inputs et les digests via `skopeo inspect`, sans télécharger les couches
OCI. Les builds Nix ne prouvent pas le démarrage des applications dans ces images.

Le nettoyage des anciennes générations Nix est quotidien, avec une rétention de quatorze jours. Les versions de Nextcloud et
`system.stateVersion` restent explicites : leurs migrations ne doivent pas être
assimilées à une simple mise à jour de dépendances.

Voir [la procédure de migration et de reprise](docs/operations.md) avant la première activation.

Avant activation, le contrôleur vérifie les dépendances absentes de chaque cible et
conserve une marge de disque. `REPO_DIR="$PWD" python3 scripts/fleet.py --preflight`
construit le checkout local et contrôle la capacité sans transfert ni activation.
Les images OCI disposent d'une marge supplémentaire, mais leur taille décompressée
reste à vérifier lorsque leurs versions changent.

### Mises à jour autonomes

Chaque dimanche, GitHub actualise les dépendances et ouvre une PR de suivi.
Il lance explicitement la CI pour éviter l'approbation des événements générés par
le robot. Après les tests et les 20 builds, seul le commit testé est avancé sur
`main` (fast-forward), puis une CI de `main` est lancée explicitement. Le contrôleur
le récupère à son prochain passage horaire. Aucun PAT supplémentaire nécessaire.
Une divergence de `main`, un contrôle échoué ou une protection de branche bloque
la promotion ; les protections GitHub ne sont pas contournées.

Cette chaîne nécessite une première publication et installation du contrôleur
selon `docs/operations.md`. Les redémarrages nécessaires restent manuels.
