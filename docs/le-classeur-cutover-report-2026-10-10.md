# Rapport de bascule Le classeur — 10 octobre 2026

## Résultat

Le domaine `https://classeur.hexaflare.net` est désormais servi par le CT NixOS
`nixos-classeur` (9903), via Cloudflare puis Caddy. PostgreSQL et les assets
stockés en base ont été restaurés depuis Neon. Le CT est intégré au GitOps
principal et la sauvegarde quotidienne hors hôte est active.

Ce rapport décrit les actions exécutées et les résultats observés pendant cette
intervention. Les horaires sont en Europe/Paris. Aucun secret n'est reproduit.

## Infrastructure et application

- CT 9903 sur `proxade` / `Storage2` : 4 CPU, 8192 MiB RAM, disque 64 GiB ;
  protection et démarrage automatique vérifiés.
- Identité SSH obtenue par le canal Proxmox authentifié, puis authentification
  du compte GitOps existant vérifiée avant publication de l'identité publique.
- Adresse Tailscale observée : `100.81.243.39`. Ingress TCP 8084 publié par
  Tailscale Serve, avec Node sur loopback derrière nginx.
- Release applicative installée :
  `1f3d919ff725f7c382e53d4b71222e6500cde6d9`, sous
  `/var/lib/le-classeur/releases/`, sélectionnée par le lien `current`.
- PostgreSQL 18, nginx, Node, cleanup et sauvegardes locaux activés.
- Secrets OAuth, Turnstile, session et origine chiffrés avec SOPS ; droits du
  rôle applicatif séparés de ceux du propriétaire PostgreSQL.
- Corrections opérationnelles : droits de traversée du répertoire de release
  et ownership du fichier de journal nginx, puis démarrage vérifié.

## Gel de la source et restauration finale

- Association du domaine personnalisé à l'ancien Worker supprimée ; cron
  Worker désactivé et liste des schedules vérifiée vide. Le Worker et Neon
  sont conservés pour la période d'observation.
- Dump final produit à 11:13:11 :
  `le-classeur-final-20261010T091311Z.dump`, 160865505 octets.
- SHA-256 :
  `fbc5025973b9a2e686c02c703fd6e9a90b2aaf9bc775ee9b46fa9750beee88d2`.
- Catalogue du dump validé ; copie conservée sur le poste, le contrôleur,
  le CT et `terraform`, avec empreintes comparées.
- Base destination recréée et restauration transactionnelle sous le rôle
  `le_classeur_beta_owner`, puis grants du runtime appliqués.
- Comparaison source/destination : **29 tables et une séquence, zéro écart**.
  Empreinte de la source avant/après gel identique.
- Node et cleanup démarrés après validation de la restauration.

## Réseau et ouverture publique

- Après autorisation explicite, règle Tailscale enregistrée : Caddy et
  `dev-nixos` vers le seul CT `100.81.243.39` en TCP 8084.
  Les deux sources ont obtenu une santé HTTP 200.
- Route Caddy activée localement depuis le contrôleur, conformément à la
  demande de mise en production sans attendre la CI initiale.
- Protection maintenue : IP Cloudflare autorisées, certificat client Cloudflare
  exigé et jeton d'origine SOPS transmis à nginx.
- Après autorisation explicite, enregistrement A créé :
  `classeur.hexaflare.net → 82.66.67.155`, proxifié, TTL automatique.
  L'API Cloudflare a confirmé le type, la cible et `proxied=true`.
- Ancien AAAA `100::` retiré avec l'association Worker.
- DNS public vérifié auprès de 1.1.1.1, 8.8.8.8 et 9.9.9.9.

## Vérifications applicatives et de sécurité

- Santé publique : HTTP 200, `{"status":"ok","runtime":"node"}`.
- Page d'accueil : HTTP 200 et titre attendu.
- API de session sans connexion : HTTP 200, réponse `null`.
- Initiation OAuth Google avec l'Origin canonique : HTTP 200, redirection vers
  `accounts.google.com` et callback
  `https://classeur.hexaflare.net/api/auth/callback/google`.
  Ce callback a été lu dans les URI autorisées du client Google.
- Une requête POST sans Origin a été refusée par l'application.
- Connexion HTTPS directe à l'origine sans certificat client : refus TLS
  `certificate required`.
- Les deux adresses Cloudflare observées ont répondu 200 avec validation TLS
  réussie. Les contrôles publics ont utilisé `curl --resolve` pour contourner
  uniquement le cache DNS négatif local, tout en conservant le domaine et TLS.
- Services Node, PostgreSQL, nginx et agent Beszel actifs après GitOps ; aucun
  message d'erreur observé dans les journaux applicatifs pendant les contrôles.

## GitOps, CI et sauvegardes

- [PR 67](https://github.com/Waddenn/nixos-config/pull/67) : route publique Caddy,
  fusionnée ; CI complète du commit `cdec6de4d58257ea2afd49f602e9370b0a3d7627`
  réussie après l'activation urgente.
- [PR 68](https://github.com/Waddenn/nixos-config/pull/68) : identité GitOps,
  canari, monitoring, proxy interne et sauvegarde hors hôte automatique.
  Assertion de sauvegarde corrigée pour vérifier le rôle du contrôleur.
- Validation : 113 tests Python réussis, trois tests ignorés ; contrôle du diff,
  format Nix et builds ciblés du CT, du contrôleur et de l'intégration réussis.
  Contrôles rapides réussis avant fusion.
- [CI complète](https://github.com/Waddenn/nixos-config/actions/runs/38041219579)
  du commit exact `de267cf92c7177aa336fa968148806db44b1a3d8` réussie.
- Réconciliation déclenchée via `internal-gitops.service` sur `dev-nixos`.
  Seulement cinq générations en dérive sélectionnées : `nixos-classeur`,
  Caddy, Gatus, Beszel et `dev-nixos` ; contrôleur activé en dernier.
- Rapport final `/var/lib/internal-gitops/last-run.json` : révision `de267cf…`,
  `error=null`, **16 hôtes convergés**. Service terminé avec succès.
- Dumps post-bascule validés puis copiés sur le contrôleur et sur
  `terraform:/root/le-classeur-backups/`, avec comparaison SHA-256.
- `le-classeur-offhost-backup.service` exécuté dans son environnement systemd :
  `Result=success`, `ExecMainStatus=0`.
- Minuteur hors hôte actif ; prochaine échéance observée :
  **11 octobre 2026 à 03:17:10 Europe/Paris**, puis quotidien autour de 03:15.
  Rétention locale du CT : 14 jours ; aucune suppression automatique hors hôte.
- Branches de travail fusionnées supprimées après comparaison avec `main`.

## Points restants et précautions de reprise

- Une connexion utilisateur Google complète avec retour et session authentifiée
  reste à tester : l'initiation et la configuration du callback sont validées.
- Au dernier contrôle, le résolveur Tailscale conservait une réponse négative
  avec 509 secondes de TTL restantes. Les résolveurs publics voyaient déjà
  le nouveau record. Il s'agit d'un état transitoire observé, pas d'une preuve
  de résolution actuelle sur tous les appareils.
- Aucune opération économique réelle n'a été rejouée pour tester en production.
- Worker, Neon et sauvegardes conservés ; aucune résiliation effectuée.
- Après de nouvelles écritures sur le CT, un retour vers Neon nécessite un gel
  et une migration inverse vérifiée. Un simple changement DNS perdrait ces
  nouvelles écritures.
- Prévoir un exercice périodique de restauration du dump hors hôte et choisir
  sa rétention selon l'espace mesuré.
