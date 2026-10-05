# Migration, exploitation et reprise

## Première activation de cette révision

La configuration est préparée localement. Aucun déploiement, redémarrage, changement
Proxmox, publication Git ou rotation de webhook n'est réalisé par les tests.

1. Revoir les changements d'images : les digests initiaux correspondent aux registres
   lors de la préparation, pas nécessairement aux images actuellement en exécution.
2. Fusionner la révision et attendre la CI complète du commit de `main`.
3. Sur `dev-nixos`, arrêter temporairement le timer avant le bootstrap, puis attendre
   la fin d'une éventuelle exécution de `internal-gitops.service`.
4. Récupérer la révision et appeler l'agent du nouveau checkout avec son SHA complet :

```bash
sudo systemctl stop internal-gitops.timer
# Vérifier qu'aucune opération n'est encore active avant de continuer.
systemctl is-active internal-gitops.service
cd /home/nixos/nixos-config
git fetch origin main
revision=$(git rev-parse origin/main)
# Checkout de migration séparé pour préserver les modifications locales éventuelles.
git worktree add --detach /var/tmp/nixos-colmena-bootstrap "$revision"
sudo env REPO_DIR=/home/nixos/nixos-config \
  bash /var/tmp/nixos-colmena-bootstrap/scripts/pull-update-host.sh "$revision"
```

L'agent évalue la révision Git directement et préserve le checkout de travail.
Si le résultat est `reboot-required`, redémarrer le contrôleur dans une fenêtre de
maintenance et vérifier sa génération. Le timer peut être réactivé par l'activation
NixOS ; sa garde CI reste obligatoire.

```bash
sudo systemctl start internal-gitops.timer
sudo systemctl start internal-gitops.service
sudo journalctl -u internal-gitops.service -n 100 --no-pager
```

La première exécution migre les canaris, puis le reste des cibles. L'ancien agent
pull est retiré des cibles lors de cette activation. Conserver leurs anciens checkouts
jusqu'à validation, puis les retirer séparément s'ils ne servent plus.

## Accès et tests applicatifs

Le contrôleur utilise SSH root sur les noms de la flotte, comme le déploiement
précédent. OpenSSH refuse toujours le login root direct ; l'accès Tailscale SSH
et ses ACL doivent donc être fonctionnels. Préserver un accès console Proxmox
indépendant pendant la migration.

Les sondes de canaris testent Authelia directement et via le domaine public servi
par Caddy. Un code HTTP différent de 200, notamment une redirection, ne valide pas
la sonde. Chaque unité est vérifiée individuellement. Un test de connexion utilisateur
complet et la restauration de données restent des validations distinctes.

Le profil Tailscale annonce maintenant l'exit node de manière déclarative.
L'approbation dans Tailscale reste nécessaire. Les sous-réseaux existants ne sont
pas inventés : leurs annonces doivent être relevées sur le routeur puis déclarées
via `my-services.networking.tailscale.extraSetFlags`.

## Incident de déploiement

- `insufficient-space` : transfert bloqué ; vérifier les générations retenues, le store Nix et les volumes Docker.
- `unreachable` : vérifier DNS, Tailscale, ACL et accès console.
- `unhealthy-or-diverged` : vérifier services applicatifs et génération active.
- `reboot-required` : génération préparée, redémarrage à planifier.
- CI absente/en échec : corriger ou attendre la CI ; `reconcile` ne contourne pas cette garde.
- Échec sur une cible joignable : le contrôleur n'est pas mis à jour ; corriger puis relancer.
- Cible secondaire injoignable : signalée et retentée chaque heure ; le contrôleur
  peut se mettre à jour si toutes les cibles joignables sont conformes.

Lire `last-run.json` et les journaux systemd. Pour une configuration sans migration
de données, la génération précédente peut servir à une reprise manuelle via console.
Pour un service ayant migré sa base, restaurer une sauvegarde cohérente avec la version
applicative plutôt que supposer qu'un rollback Nix rétablit les données.

## Migration Nextcloud 32 vers 33

Cette révision ne couvre que le passage majeur 32 vers 33. Ne pas remplacer le paquet
par Nextcloud 34 avant validation complète de la version 33. Une activation Nix peut
lancer la migration de schéma : un retour à la génération précédente ne restaure ni la
base PostgreSQL ni le répertoire de données.

Avant la fenêtre de maintenance, obtenir une CI complète verte lancée explicitement
sur la branche de PR (`workflow_dispatch`), puis
arrêter le timer sur `dev-nixos` et vérifier qu'aucun déploiement n'est actif. Garder
le timer arrêté jusqu'à la validation finale afin qu'une fusion ne déclenche pas la
migration avant la sauvegarde :

```bash
sudo systemctl stop internal-gitops.timer
systemctl is-active internal-gitops.service
```

Sur `nextcloud-pgsql`, relever l'état initial et préparer une sauvegarde cohérente.
Le timer déclaratif `postgresqlBackup` conserve un dump quotidien dans
`/var/backup/postgresql`, mais il ne remplace pas cette sauvegarde juste avant migration.
La copie doit être placée sur un stockage ayant assez d'espace et, idéalement, distinct
du disque du conteneur.

```bash
sudo -u nextcloud nextcloud-occ status
sudo -u nextcloud nextcloud-occ app:list --shipped=false
sudo -u postgres psql -d nextcloud -Atc \
  "select current_database(), pg_size_pretty(pg_database_size(current_database()));"
df -h /var/lib/nextcloud /var/backup

stamp=$(date -u +%Y%m%dT%H%M%SZ)
backup_dir="/var/backup/nextcloud-migrations/$stamp"
sudo install -d -m 0700 -o postgres -g postgres "$backup_dir"
sudo -u nextcloud nextcloud-occ maintenance:mode --on
sudo -u postgres pg_dump --format=custom --file="$backup_dir/nextcloud.pgdump" nextcloud
sudo tar --xattrs --acls --numeric-owner -C /var/lib -cpf \
  "$backup_dir/nextcloud-datadir.tar" nextcloud
sudo -u postgres pg_restore --list "$backup_dir/nextcloud.pgdump" >/dev/null
sudo tar -tf "$backup_dir/nextcloud-datadir.tar" >/dev/null
sudo sha256sum "$backup_dir"/* | sudo tee "$backup_dir/SHA256SUMS"
sudo sha256sum -c "$backup_dir/SHA256SUMS"
```

Ne poursuivre que si chaque commande réussit, si les deux archives sont non vides et
si leur vérification réussit. Laisser le mode maintenance actif. Fusionner ensuite,
attendre la CI complète verte du commit exact de `main`, puis construire ce commit sans
l'activer avant tout déploiement autorisé :

```bash
git fetch origin main
revision=$(git rev-parse origin/main)
git worktree add --detach /var/tmp/nextcloud-33-deploy "$revision"
cd /var/tmp/nextcloud-33-deploy
nix build --no-link --no-write-lock-file \
  .#nixosConfigurations.nextcloud-pgsql.config.system.build.toplevel
```

Activer uniquement `nextcloud-pgsql` selon la procédure de déploiement autorisée, puis
contrôler :

```bash
sudo -u nextcloud nextcloud-occ status
sudo -u nextcloud nextcloud-occ db:add-missing-indices
sudo -u nextcloud nextcloud-occ db:add-missing-primary-keys
sudo -u nextcloud nextcloud-occ db:add-missing-columns
sudo -u nextcloud nextcloud-occ maintenance:repair
sudo -u nextcloud nextcloud-occ status
sudo -u nextcloud nextcloud-occ app:list --shipped=false
sudo -u postgres psql -d nextcloud -Atc \
  "select count(*) from oc_migrations;"
curl --fail --silent --show-error http://192.168.40.116/status.php
curl --fail --silent --show-error https://nextcloud.hexaflare.net/status.php
systemctl --failed
journalctl -u nextcloud-setup.service -u phpfpm-nextcloud.service \
  -u postgresql.service -u nginx.service --since "30 minutes ago" --no-pager
sudo -u nextcloud nextcloud-occ maintenance:mode --off
```

Le succès exige Nextcloud 33 installé, `maintenance: false`, `needsDbUpgrade: false`,
les services sans échec, les deux sondes HTTP à 200, les applications nécessaires
activées et un test manuel de connexion, lecture et écriture d'un fichier. Conserver
la sauvegarde et surveiller les journaux avant toute proposition de passage à 34. Une
fois ces critères remplis, réactiver `internal-gitops.timer` sur `dev-nixos`.

En cas d'échec avant migration du schéma, corriger ou réactiver la génération 32 puis
désactiver le mode maintenance. Après toute migration de schéma, ne pas simplement
revenir à la génération 32. Depuis la console Proxmox si l'accès SSH n'est plus fiable,
conserver l'état défaillant et restaurer les deux éléments du même `backup_dir` :

```bash
sudo systemctl stop nginx.service phpfpm-nextcloud.service
failed_stamp=$(date -u +%Y%m%dT%H%M%SZ)
sudo mv /var/lib/nextcloud "/var/lib/nextcloud.failed-$failed_stamp"
sudo tar --xattrs --acls --numeric-owner -C /var/lib -xpf \
  "$backup_dir/nextcloud-datadir.tar"
sudo -u postgres dropdb nextcloud
sudo -u postgres createdb --owner=nextcloud nextcloud
sudo -u postgres pg_restore --dbname=nextcloud "$backup_dir/nextcloud.pgdump"
sudo nix-env --rollback --profile /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
sudo -u nextcloud nextcloud-occ status
sudo -u nextcloud nextcloud-occ maintenance:mode --off
```

Vérifier avant le rollback que la génération précédente correspond bien à Nextcloud
32 (`nix-env --list-generations --profile /nix/var/nix/profiles/system`). Ne supprimer
l'état `.failed-*` qu'après validation de la restauration et conserver les archives.

## Périmètre Proxmox

La mise en place de nouvelles sauvegardes est reportée à la demande de l'utilisateur.
Cette refonte ne modifie pas les sauvegardes Proxmox existantes. Le dump PostgreSQL
Nextcloud local ajouté ici protège les migrations applicatives mais ne constitue pas
une sauvegarde indépendante du conteneur.

À valider avant de conclure à la haute disponibilité : quorum, stockage disponible
sur les nœuds de reprise, ressources HA déclarées et RAM disponible après perte d'un
nœud. Ne pas changer les privilèges LXC sans vérifier les UID/GID et les montages.
Le paramètre Nix `proxmoxLXC.privileged` adapte le système invité ; il ne convertit
pas le conteneur dans Proxmox.

## Secrets

Le webhook en clair de Gatus a été retiré du code. Gatus utilise le secret SOPS
`discord-webhook`, converti en environnement uniquement dans `/run`, accessible à root.
L'ancien webhook reste dans l'historique Git : le révoquer dans Discord et effectuer
la rotation du secret si nécessaire. Aucun secret n'a été déchiffré pour cette refonte.

## Sources techniques

- [Colmena : options et parallélisme](https://colmena.cli.rs/0.4/reference/cli.html)
- [Proxmox : conteneurs et sauvegardes des montages](https://pve.proxmox.com/pve-docs/chapter-pct.html)
- [Tailscale : exit nodes](https://tailscale.com/docs/features/exit-nodes)

## Permissions du dépôt du contrôleur

Le bootstrap root et le service nixos partagent les métadonnées Git. Le dépôt
existant a été configuré avec `core.sharedRepository=group`, groupe `users`,
écriture de groupe et bit setgid sur ses répertoires `.git`. Conserver ces droits
lors d'une restauration ou recréation du checkout afin que les fetch root ne
bloquent pas les fetch du service. Le contenu applicatif n'est pas concerné.

## Inventaire Beszel

Beszel suit automatiquement les `nixosConfigurations` dont l'agent est activé.
Les dossiers `hosts/_…` sont exclus par la découverte des hôtes ; une machine
simplement injoignable reste surveillée. Les machines hors NixOS sont déclarées
uniquement dans `modules/data/beszel-hosts.nix` (`externalHosts`).

Le fichier YAML est appliqué au démarrage du hub et son changement provoque un
redémarrage du seul service Beszel. Ne pas ajouter les machines NixOS dans l'UI :
le fichier fait autorité. Pour conserver l'historique lors d'un changement de nom
d'affichage, garder le nom existant dans `nameOverrides`. Beszel identifie une
entrée par le triplet nom/adresse/port ; changer ce triplet crée une nouvelle entrée.

Avant chaque changement de fichier, les bases SQLite et l'ancien YAML sont archivés
avec des droits privés dans `/home/nixos/beszel_data/inventory-backup-*`.
Les entrées retirées et leur historique ne sont plus disponibles dans l'UI ; les
archives permettent une récupération. Elles sont conservées sans purge automatique.
Pour une restauration complète, arrêter Beszel, sauvegarder l'état présent, restaurer
les deux bases et l'ancien YAML, puis utiliser la configuration Nix correspondante
avant redémarrage pour éviter de réappliquer immédiatement le nouvel inventaire.

## Déploiements ciblés

La CI évalue toujours l'inventaire et vérifie les scripts, le formatage et la parité
Colmena/NixOS. Elle construit uniquement les systèmes dont le chemin de sortie Nix
change depuis une révision ancêtre de `main` ayant une CI réussie. Un commit précédent
non validé ne sert jamais de référence. Les nouveaux hôtes sont construits ; les hôtes
retirés disparaissent de la matrice. Une modification documentaire peut ne lancer
aucune construction ; le job `validation` vérifie explicitement ce cas.

Un changement du lock, du flake, des points d'entrée partagés ou du mécanisme de CI
force les constructions complètes. L'absence de référence fiable ou l'impossibilité
de l'évaluer revient aussi au parcours complet. `ci-plan.json`, disponible en artefact
GitHub, indique la référence, les systèmes sélectionnés et leurs chemins attendus.

Le contrôleur garde sa garde CI sur le commit exact. Il sonde les générations actives
et préparées en parallèle (8 connexions maximum), vérifie la santé des systèmes déjà
conformes et construit seulement les systèmes en dérive. Les canaris modifiés sont
activés en premier ; les canaris inchangés doivent toujours être sains. Le contrôleur
n'est réactivé que si son propre système change, après les cibles joignables.

Une machine hors ligne reste signalée et retentée au cycle suivant ; elle ne déclenche
pas de construction inutile. Un rollback manuel est détecté par la génération réelle.
Le journal donne la durée du précontrôle et le nombre de systèmes à construire.

Validation du 11 septembre 2026 : la comparaison réelle des sorties Nix entre
`d0d0668` et `eec6996` (synchronisation de l'inventaire Beszel) sélectionne seulement
`beszel`, sur les 14 hôtes restants. Les six hôtes retirés ne sont pas construits.
Le précontrôle réel sans changement, testé en interdisant les commandes de construction
et d'activation, termine en 8 secondes pour 14 hôtes, dont trois injoignables. Ce temps
exclut la récupération Git et l'évaluation Nix du cycle complet.

## Version commune du serveur et des agents Beszel

`lib/beszel-release.json` est l'unique référence de version pour le serveur Docker
et les agents NixOS. Le serveur utilise le tag exact et le digest de cette release ;
`pkgs/beszel-agent.nix` installe son binaire officiel Linux amd64, avec checksum fixé
et test de `--version`. Les agents restent des services natifs, sans Docker ni
mise à jour autonome hors Nix. L'inventaire et les données du hub sont inchangés.

Le workflow hebdomadaire et `just update` exécutent `scripts/update-beszel.py` :
lecture de la dernière release stable, vérification de l'archive contre les checksums
upstream et résolution du digest du tag serveur correspondant, puis écriture atomique
du fichier commun. Beszel est exclu de `container-images.json` pour éviter une seconde
source indépendante. Si un téléchargement, checksum ou digest échoue, le fichier reste
inchangé. La CI exécute l'agent et le serveur épinglés pour vérifier leurs versions.

L'agent est inclus dans les contrôles de santé du déploiement. Les hôtes NixOS hors
ligne recevront la version commune à leur retour. Les machines externes (`externalHosts`)
restent administrées séparément ; déclarer leur présence ne gère pas leurs logiciels.

## Branches de travail et PR

Chaque changement part de `main` à jour dans une branche courte `codex/<sujet>`.
Un simple push hors `main` ne déclenche aucune CI. Une PR brouillon n'exécute
aucun job : GitHub peut afficher une exécution entièrement ignorée, sans runner.
L'ouverture d'une PR prête, son passage à l'état prêt et ses nouveaux pushes
lancent les tests Python, ShellCheck et le contrôle de whitespace, sans build Nix.
Repasser en brouillon annule le run encore actif et suspend ces contrôles.

Après fusion, la CI du SHA exact de `main` exécute le parcours complet avant tout
déploiement. C'est l'unique CI complète automatique d'une fonctionnalité ordinaire.
Une erreur Nix peut donc être découverte après fusion : le déploiement reste bloqué
jusqu'à une correction ou un revert dont la CI réussit. Un résultat vert de PR ne
prouve pas que les configurations Nix sont valides.

Les lancements manuels (`workflow_dispatch`) restent complets. La mise à jour
hebdomadaire continue à demander une CI complète sur `update-flake-lock` avant son
intégration automatique, puis sur `main`. Ce contrôle préalable est également
possible sur demande pour une migration sensible.

### Promotion de la validation complète après fusion — désactivée

Le prototype de promotion par arbre n'est pas une preuve de validation suffisante.
La CI de chaque SHA de `main` suit le parcours complet, comme les lancements
manuels. Seules les PR prêtes exécutent les contrôles rapides ; les brouillons et
les simples pushes de branche n'exécutent aucun job.
Le garde `ci-gate` vérifie lui-même le type d'événement et refuse
un résultat rapide, un mode absent ou une validation omise sur `main`.

Le workflow publieur est supprimé, aucun statut de promotion n'est consommé et
`scripts/ci-promotion.py` refuse explicitement les anciens appels `publish` et
`verify-main`. Une preuve absente, imitée, ambiguë, périmée ou invalide ne peut donc
pas éviter le parcours complet. Voir [l'audit et les prérequis de réactivation](ci-promotion-security.md).

Les builds complets utilisent toujours le cache binaire signé
`waddenn-nixos`. Une sortie présente peut être substituée, une sortie absente doit
être construite. Cela économise les reconstructions quand les chemins Nix sont
identiques. La sélection des
systèmes affectés reste assurée par `scripts/plan-ci.py`.

Le contrôleur attend toujours une CI réussie du SHA exact de `main`. Les canaris,
les contrôles de santé et d'espace, le ciblage des générations en dérive et le rôle
exclusif de `dev-nixos` sont conservés. Aucun statut de promotion ni succès de
branche ne constitue une autorisation de déploiement.

## Capacité disque et rétention Nix

Les conteneurs déclarés dans `provisioning/services.nix` disposent d'au moins
16 Gio ; cette valeur est validée par l'inventaire. La commande explicite
`nix develop -c python3 provision.py resize probe` dans `provisioning/`, sur
`dev-nixos`, réconcilie les agrandissements déclarés avec le state OpenTofu
existant. Elle sauvegarde l'état et refuse création, réduction, remplacement
et toute modification autre que la taille des disques existants.

Le nettoyage quotidien `nix-gc.service` conserve les trois dernières générations
système, plus celles nécessaires au système actif et au prochain démarrage.
Les deux systèmes sont aussi protégés par des racines GC actualisées avant le
nettoyage. Les profils utilisateur et les données applicatives ne sont pas purgés.
La commande `nix-storage-cleanup --prune` applique cette rétention puis collecte
les fichiers inutilisés ; sans argument, elle ne supprime aucune génération.

En cas de capacité insuffisante, le déployeur lance une seule collecte sans
suppression de générations, puis recalcule les fichiers manquants, la marge de
25 % et la réserve de 1 Gio (3 Gio pour OCI). Le blocage reste obligatoire si
la place manque. `last-run.json` inclut les mesures de capacité et les journaux
affichent les Gio disponibles et nécessaires.

`internal-gitops-capacity.timer` mesure la flotte chaque heure sans build ni
activation, indépendamment de la CI. Les alertes Discord existantes signalent
moins de 3 Gio libres (5 Gio sur le contrôleur) ou moins de 20 % libres, puis
le retour à la normale. Elles sont dédupliquées tant que les hôtes concernés
ne changent pas ; un hôte injoignable n'est jamais déclaré rétabli. Une mesure
indisponible reste explicite dans le rapport et les journaux, sans faire échouer
le service de surveillance. Les mesures
sont dans `/var/lib/internal-gitops/capacity.json`.

## Accès à l'origine des sites Cloudflare

Caddy réserve `auth`, `bitwarden`, `homeassistant`, `jellyseerr`, `immich` et
`codex.hexaflare.net` aux connexions dont le pair TCP appartient à Cloudflare.
La vérification `remote_ip` précède l'authentification et le reverse proxy dans
un bloc `route`; les en-têtes `X-Forwarded-For` et `CF-Connecting-IP` ne peuvent
pas autoriser une connexion directe. Aucune exception LAN/Tailscale n'est ajoutée
à ces domaines. Nextcloud garde son accès direct et le proxy interne sur 8085
conserve sa propre restriction Tailscale. La sonde de santé Caddy utilise le
domaine public `auth.hexaflare.net` et passe donc par Cloudflare.

Les plages sont centralisées dans `lib/cloudflare-ips.json`, vérifiées le
5 octobre 2026 avec `https://api.cloudflare.com/client/v4/ips` (champs
`result.ipv4_cidrs` et `result.ipv6_cidrs`). Lors d'une mise à jour de ces plages,
actualiser ce fichier par PR, vérifier le format et refaire les contrôles avant
déploiement. Une erreur de récupération ne doit jamais vider la liste autorisée.

Test comportemental dans un checkout isolé disposant de Nix :

```sh
nix eval --json .#nixosConfigurations.caddy.config.services.caddy.virtualHosts > /tmp/caddy-vhosts.json
caddy_package=$(nix build --no-link --print-out-paths .#nixosConfigurations.caddy.config.services.caddy.package)
nix shell --inputs-from . nixpkgs#python3 --command python3 scripts/check-caddy-origin.py "$caddy_package/bin/caddy" /tmp/caddy-vhosts.json
```

Ce test démarre un serveur temporaire uniquement sur loopback, remplace les
proxies applicatifs et d'authentification par des réponses locales, puis vérifie
56 requêtes : refus direct, refus avec en-têtes forgés, pair autorisé simulé et
accès direct Nextcloud. Il ne contacte aucun backend de production.

Après activation, vérifier chaque domaine via son DNS public, puis via
`curl --resolve DOMAINE:443:IP_ORIGINE https://DOMAINE/` depuis Internet : les
six domaines doivent répondre 403 en accès direct, même avec de faux en-têtes,
et fonctionner via Cloudflare. Vérifier séparément Nextcloud et la sonde de santé.

### Certificat client Cloudflare dédié (AOP)

Le filtrage IP est complété par Authenticated Origin Pulls au niveau de la zone
`hexaflare.net`, avec un certificat client propre à cette zone. Caddy fait confiance
uniquement à `lib/cloudflare-aop-ca.pem`, et non à l'autorité AOP partagée de
Cloudflare. `lib/cloudflare-aop-client.pem` est une copie publique permettant de
contrôler l'expiration. Aucune clé privée ni jeton API n'entre dans Git ou Caddy.
Les clés de cette émission sont conservées hors dépôt dans le répertoire privé
`~/.local/share/nixos-config/cloudflare-aop/2026-10-05/` du poste d'administration.

Le réglage `my-services.networking.caddy.requireOriginCertificate` permet une
mise en place en deux étapes : `false` demande et vérifie le certificat s'il est
présent, puis `true` le rend obligatoire. Ne passer à `true` qu'après observation
de l'empreinte attendue dans `aop_client_fingerprint` des journaux d'accès des six
sites. Le certificat public se contrôle avec
`openssl x509 -in lib/cloudflare-aop-client.pem -noout -fingerprint -sha256`.
`strict_sni_host on` refuse un Host protégé présenté avec le SNI Nextcloud (421).
Nextcloud ne demande pas de certificat client.

Test TLS complémentaire (certificats de test éphémères, aucun accès production) :

```sh
nix shell --inputs-from . nixpkgs#python3 nixpkgs#openssl --command python3 scripts/check-caddy-mtls.py "$caddy_package/bin/caddy" /tmp/caddy-vhosts.json
```

Il vérifie 50 cas en TLS 1.2 et 1.3 : certificat autorisé, certificat inconnu,
absence de certificat selon le mode, contournement SNI/Host et exception Nextcloud.
Lorsque le certificat devient obligatoire, les tests directs sans certificat
doivent échouer dès TLS, avant le 403 HTTP du filtrage IP. La lecture publique des
pages via Cloudflare et la sonde de santé doivent continuer à fonctionner.

Le certificat client initial expire le 4 octobre 2028. Le timer quotidien
`cloudflare-aop-expiry.timer` vérifie les certificats publics client et CA avec
une marge de 60 jours. Un échec apparaît dans `systemctl --failed` et dans le
journal de `cloudflare-aop-expiry.service`; ce contrôle ne renouvelle pas le
certificat et n'envoie pas de notification externe.

Pour renouveler : émettre un nouveau certificat client signé par la même CA
(EKU clientAuth, CA:FALSE), l'importer via l'API AOP de la zone, vérifier son
activation et sa présentation sur tous les sites, puis actualiser la copie
publique dans Git et déployer. Si la CA change, déployer d'abord un bundle de
confiance contenant les deux CA avant de changer le certificat Cloudflare.
Conserver l'ancien certificat pendant la transition. Le jeton de maintenance
requiert `Zone / SSL and Certificates / Edit`, limité à `hexaflare.net`.

En cas de panne AOP, restaurer temporairement `requireOriginCertificate = false`
via le parcours de livraison habituel avant de désactiver AOP côté Cloudflare.
Un certificat invalide encore présenté reste refusé en mode `verify_if_given` :
si nécessaire, revenir à la configuration précédant AOP, qui conserve le filtre
IP. Ne pas remplacer la CA dédiée par une confiance générale dans tous les
certificats Cloudflare.

AOP authentifie le lien Cloudflare–Caddy. Il ne remplace pas la 2FA des applications,
ne masque pas l'IP partagée avec Nextcloud/Plex et n'empêche pas une saturation du
lien Internet.
