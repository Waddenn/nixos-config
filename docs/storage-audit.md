# Contrôle d'espace du 10 septembre 2026

Mesures réalisées par SSH depuis le poste de développement. Aucun déploiement ni
redémarrage des applications pendant ce contrôle.

## Résultat

12 hôtes joignables passent le précontrôle d'espace de la refonte avec le lock
initial. 8 hôtes ne peuvent pas être validés depuis ce poste : adguardhome,
ai-controller, bourse-dashboard, glance, gotify, immich, paperless et valheim.
Un échec SSH ne permet pas de conclure à une panne de l'application.

| Hôte | Espace libre (Gio) |
| --- | ---: |
| dev-nixos, avant nettoyage | 4,5 |
| dev-nixos, après nettoyage | 15,2 |
| authelia | 25,6 |
| beszel | 5,4 |
| caddy | 8,1 |
| calibre | 14,2 |
| gatus | 9,4 |
| jellyseerr | 16,4 |
| nextcloud-pgsql | 13,0 |
| tailscale-exit-node | 13,4 |
| tailscale-subnet | 10,8 |
| terraform | 8,2 |
| vaultwarden | 6,1 |

Le ramasse-miettes standard `nix-store --gc` a été exécuté sur dev-nixos. Il a
supprimé 10 198 chemins non référencés. Les générations 68, 69 et 70, dont la 70
active, sont conservées. Aucun volume Docker ni donnée applicative n'a été nettoyé.

Colmena a construit localement Authelia et dev-nixos avec le lock de la PR 24
(commit c2ea5a883f5af8cda0200a8dd60a38451b9e02c9). Les nouveaux paquets absents
représentent environ 362 Mio pour Authelia et 351 Mio pour dev-nixos. Ces mesures
portent sur leurs générations système, pas sur les besoins temporaires de
construction de toute la flotte sur le contrôleur.

Les sondes de santé réelles des canaris Authelia et Caddy passent.

## Prévention ajoutée au dépôt

- Avant transfert, comparaison des références Nix nécessaires avec les chemins déjà
  valides sur la cible. Les chemins communs aux générations ne sont pas comptés deux fois.
- Budget : taille NAR des chemins absents + 25 % + 1 Gio de réserve ; 2 Gio
  supplémentaires pour les hôtes OCI. C'est une estimation prudente, pas une garantie
  sur la taille décompressée des images Docker ou les écritures des applications.
- Au moins 5 Gio libres exigés sur le contrôleur avant construction.
- Nettoyage quotidien des anciennes générations de plus de 14 jours.
- GC automatique des chemins non référencés sous pression pendant les opérations Nix
  concernées : seuils 1/3 Gio sur les cibles et 5/8 Gio sur le contrôleur.

Ces nouvelles règles sont préparées et testées localement. Elles ne sont pas encore
activées sur le cluster. Le nouveau contrôleur récupérera `main` sur GitHub après
son installation ; les cibles recevront les systèmes via Colmena.

## Mise à jour GitHub validée localement

La refonte combinée au lock de la PR 24 passe `nix flake check` avec construction
des vingt configurations. Les douze hôtes joignables passent aussi le contrôle
de capacité pour cette mise à jour ; les huit autres restent non vérifiés.

| Hôte | Nouveaux chemins Nix (Gio) | Budget avec marge (Gio) | Libre (Gio) |
| --- | ---: | ---: | ---: |
| authelia | 0.35 | 1.44 | 25.64 |
| beszel | 0.53 | 3.66 | 5.36 |
| caddy | 0.30 | 1.38 | 8.14 |
| calibre | 0.53 | 3.66 | 14.24 |
| dev-nixos | 0.34 | 1.43 | 15.24 |
| gatus | 0.32 | 1.40 | 9.43 |
| jellyseerr | 1.18 | 2.47 | 16.36 |
| nextcloud-pgsql | 0.26 | 1.32 | 13.04 |
| tailscale-exit-node | 0.26 | 1.32 | 13.40 |
| tailscale-subnet | 0.26 | 1.32 | 10.85 |
| terraform | 0.37 | 1.46 | 8.22 |
| vaultwarden | 0.26 | 1.32 | 6.09 |
