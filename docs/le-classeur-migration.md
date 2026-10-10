# Migration Le classeur vers NixOS

État de cette préparation : déclaration proposée `classeur` (CT **9903**, VMID
vérifié libre avant création), `proxade` / `Storage2`, 4 CPU, 8192 MiB, 64 GiB.
Le service reste isolé du GitOps principal et la route publique reste désactivée.
Ce document ne constitue pas une preuve de création, restauration ou bascule.

La création isolée a ensuite été vérifiée le 10 octobre 2026 : CT 9903 en cours
d'exécution, hostname `nixos-classeur`, puis porté à 8 GiB RAM / 64 GiB disque
et 4 CPU ; DHCP observé
`192.168.1.159`. La découverte authentifiée a vérifié sa clé SSH et son hostname.
Cette IP est un fait de cette exécution, pas une adresse à recopier dans Nix.
Le bootstrap SSH est construit et actif ; aucune release ni base applicative
n'a été installée. Le build applicatif complet attend le SOPS réel, sans faux secret.

## Contrat de livraison

- Release immuable dans `/var/lib/le-classeur/releases/<commit>/` :
  `build/server/index.js`, `build/client/`, dépendances Node de production et
  manifeste/checksums. Node 24 est fourni par NixOS.
- `/var/lib/le-classeur/current` est un symlink choisi explicitement après
  validation. Les releases appartiennent à `root:le-classeur`, sont lisibles
  mais jamais modifiables par `le_classeur_app`.
- Node écoute `127.0.0.1:8083`. Nginx écoute 8084 et impose le Host canonique.
  `/health` sert aux contrôles du provisionneur. Les autres routes sont refusées
  tant que `application.trustedProxyCIDRs` ne contient pas l'adresse **observée**
  de Caddy, typiquement son IP Tailscale avec `/32`. Ne pas ajouter tout le tailnet.
  Seul Caddy transmet l'IP visiteur vérifiée par Cloudflare ; l'ACL Tailscale doit
  aussi limiter ce flux. `tag:nixos-pilot` n'est pas une isolation réseau.
  Un jeton origin partagé SOPS est **obligatoire** sur toutes les routes hors
  `/health`, y compris loopback : Tailscale userspace peut présenter une IP locale.
  Caddy écrase `Authorization` avec son bearer ; nginx valide le bearer puis
  supprime cet en-tête avant Node. Le fichier partagé `provisioning/secrets/classeur-origin.yaml`
  est chiffré pour Caddy, la clé CT authentifiée et les clés de récupération.
  Aucun jeton en Nix store ni dans les logs. L'authentification applicative demeure
  les cookies existants ; aucun bearer métier n'est ajouté.
- PostgreSQL 18 n'écoute aucun port TCP. La connexion runtime utilise
  `postgresql://le_classeur_app@localhost/le_classeur_beta?host=/run/postgresql`
  et l'authentification Unix `peer`. `le_classeur_beta_owner` possède la base et
  le schéma migré ; le runtime n'a jamais ce rôle. Appliquer les droits runtime
  exacts du projet après restauration, puis tester les opérations réelles.
  Le pool Node doit être borné (au plus 15 connexions par processus, cleanup
  compris avec une marge dans les 50 connexions PostgreSQL) et conserver une
  connexion pour toute transaction.
- Le secret SOPS `classeur-environment` contiendra les valeurs OAuth Google et
  la liste d'accès héritée. Le template d'environnement systemd ajoute les
  secrets Turnstile et de signature de session depuis leurs fichiers SOPS
  distincts. La clé de session d'origine étant introuvable, sa rotation
  imposera une reconnexion ; les comptes et cartes en base restent conservés.
  Il ne doit
  pas modifier les valeurs fixes `APP_ENV`, `APP_RUNTIME`, `APP_ORIGIN`, `HOST`,
  `PORT` ou `DATABASE_URL`. Son fichier chiffré est
  `provisioning/secrets/classeur.yaml`, pour la clé CT découverte et les deux
  clés de récupération, sans accès du contrôleur ni de Caddy au contenu.
  Le secret Turnstile actuel a été récupéré sans rotation et conservé dans
  `provisioning/secrets/classeur-turnstile.yaml`, chiffré pour les mêmes
  destinataires. La nouvelle clé de session est dans
  `provisioning/secrets/classeur-session.yaml`, également chiffrée pour le CT
  et les clés de récupération. Le jeton Caddy est dans `classeur-origin.yaml` avec des
  destinataires différents. Ne jamais versionner le clair ; vérifier le
  déchiffrement sur le CT et restaurer depuis une copie chiffrée avant toute
  rotation. Après une rotation, mettre à jour SOPS et redémarrer uniquement les
  services concernés, puis vérifier l'authentification et les sauvegardes.

## Préparation sur dev-nixos

Utiliser un checkout isolé et les accès du contrôleur existant. Auditer VMID,
capacité réelle de `Storage2`, ressources libres, ACL et état Terraform avant
création. Ne jamais adopter un CT existant ni reprendre l'ancien state global.

Le 10 octobre 2026, l'API `proxade:8006` via Tailscale expirait alors que SSH
fonctionnait. Le contrôleur `192.168.1.205` atteignait l'API sur le LAN
`192.168.1.1`. Une résolution de diagnostic `curl --resolve` a confirmé la CA
existante et le nom de certificat `proxade` ; l'URL avec IP seule échoue au
contrôle du nom. Le transport de cette opération utilise un proxy CONNECT
temporaire, en loopback sur le contrôleur, qui route `proxade:8006` vers le LAN
vérifié tout en conservant TLS, le hostname et la CA. Le script reste un artefact
privé du contrôleur, sans journalisation des en-têtes. Aucun réglage global DNS,
hosts, Tailscale, firewall ou vérification TLS n'est modifié. Revérifier ce chemin
avant réutilisation ; le proxy s'arrête à la fin de chaque commande.

Le CT a été créé avec la convention pilote `start_on_boot=false`. La déclaration
proposée `startOnBoot=true` peut ensuite être appliquée avec la commande explicite
`nix develop -c python3 provision.py autostart classeur`. Son garde autorise
uniquement `false → true` sur ce CT, sans création, remplacement ni autre champ
modifié ; les CT existants doivent être no-op. Ce correctif a ensuite été activé
et vérifié : CT 9903 `onboot=1`, CT 9901/9902 toujours `onboot=0`, protection=1
sur les trois machines.

Après demande de capacité supplémentaire, l'audit a confirmé 28,9 GiB RAM et
212,2 GiB Storage2 disponibles avec charge faible sur 24 threads. Le plan
`capacity classeur` n'autorise que les augmentations CPU/RAM/disque de ce CT,
sans autre champ, création, réduction ni remplacement. Le provider a signalé
un refus lié à la protection après agrandissement effectif du disque ; un refresh
a vérifié les 64 GiB réels puis un second plan a modifié uniquement CPU/RAM.
L'état final Proxmox est 4 CPU / 8192 MiB / 64 GiB, protection et onboot actifs.
CT 9901/9902 restent inchangés. La protection n'a jamais été désactivée.

Le premier `up` complet ne peut réussir sans release et secrets applicatifs.
Séparer les étapes permet de créer la machine sans publier un faux service sain :

```sh
nix develop -c python3 provision.py authorize classeur
nix develop -c python3 provision.py prepare classeur
nix develop -c python3 provision.py infra classeur
nix develop -c python3 provision.py discover classeur
```

Après découverte, préparer le secret chiffré avant `deploy`. Les clés du CT
doivent venir du canal Proxmox authentifié. Déployer NixOS, copier une release
vérifiée et restaurer les données avant d'exiger la santé complète. Un fichier
absent empêche Node de démarrer ; le provisionneur signale cet état comme échec.

Ne pas laisser la minuterie cleanup muter une restauration en cours : arrêter
`le-classeur.service`, `le-classeur-cleanup.timer` et l'unité cleanup avant restore.
Les grants runtime, migration hashes, ownership, compteurs, réservations,
opérations/audits et checksums des assets doivent être comparés à la source.
Le schéma applicatif et ses scripts de migration restent la source de vérité.

## Sauvegarde, restauration et bascule

1. Créer un dump privé Neon et vérifier son checksum et `pg_restore --list`.
   Restaurer une copie sur une base jetable ; tester schéma et invariants avant
   d'utiliser la sauvegarde de bascule. Vérifier la version PostgreSQL source
   contre PostgreSQL 18 avant restauration.
2. Restaurer un premier snapshot dans le CT et valider l'application/auth avec
   l'origine canonique. Installer le Caddy `/32` observé dans les CIDR autorisés.
   Tester que LAN/tailnet non autorisés ne peuvent injecter d'IP visiteur.
3. Avant le dump final, empêcher **toutes** les écritures sur l'ancien Worker,
   y compris OAuth/presence/admin et son cron. Vérifier effectivement le gel ;
   un simple drapeau « économie fermée » ne suffit pas.
4. Dump final, checksum, restore dans une destination propre sous le rôle owner,
   grants runtime exacts et comparaison données/assets/invariants. Garder le
   service et cleanup arrêtés jusqu'à validation. Copier le dump final et ses
   preuves vers un stockage distinct du CT et du nœud physique.
5. Démarrer Node et cleanup, vérifier santé HTTP + base, auth, images, opérations
   atomiques et réconciliation. Ne pas rejouer d'action économique en production
   à des fins de test sans compte/procédure adaptés.
6. Activer `my-services.networking.caddy.classeurOrigin.enable = true` dans une
   modification revue. La route conserve IP Cloudflare + certificat client AOP
   avec `cloudflareOnly`. Conserver Cloudflare DNS/protection et le domaine
   `classeur.hexaflare.net`. Traiter les anciennes routes Workers avant la
   bascule DNS/origin pour éviter qu'elles continuent d'intercepter les requêtes.
   État observé le 10 octobre 2026 : le domaine possède un AAAA proxifié
   `100::` utilisé avec le domaine personnalisé Worker ; les autres services
   publics pointent vers l'IPv4 `82.66.67.155`. Vérifier de nouveau ces valeurs,
   retirer l'association du domaine personnalisé Worker, puis créer l'entrée A
   proxifiée vers l'origine Caddy lors de la bascule. La règle géographique
   Cloudflare `country access` exclut explicitement ce hostname ; préserver
   cette expression et les autres contrôles WAF.
7. Après fusion autorisée, attendre la CI verte du **SHA exact de main** avant
   activation Caddy par le contrôleur. Vérifier réellement via Cloudflare et
   vérifier que l'origine directe refuse l'accès. Ne pas annoncer la migration
   sur la seule preuve d'une PR ou d'un démarrage systemd.

La minuterie `le-classeur-backup` produit chaque nuit des dumps custom datés,
vérifie leur catalogue et écrit SHA-256. Rétention locale 14 jours, après un
nouveau dump réussi. Ce mécanisme doit être complété par une copie privée hors
CT/nœud et un exercice périodique de restauration ; le dump local ne protège pas
contre la perte du stockage. Les assets sont inclus s'ils restent dans PostgreSQL.

Proposition concrète de copie hors nœud : un timer **sur dev-nixos**, après le
dump de 02:15, tire les dumps par son accès SSH existant au CT puis les transfère
vers `root@terraform:/root/le-classeur-backups/`. Ne pas donner au CT la clé SSH
du contrôleur ni celle du stockage. Les deux répertoires doivent être root:root
0700, les dumps 0600. Commandes opérateur proposées après déploiement réel :

```sh
# Sur dev-nixos ; vérifier l'identité du stockage avant la première copie.
umask 077
mkdir -p /var/backup/le-classeur-offhost
ssh -F /var/lib/proxmox-prototype/ssh_config service-classeur \
  'systemctl start le-classeur-backup.service'
scp -F /var/lib/proxmox-prototype/ssh_config \
  'service-classeur:/var/backup/le-classeur/*.dump*' /var/backup/le-classeur-offhost/
ssh root@terraform 'umask 077; mkdir -p /root/le-classeur-backups; chmod 700 /root/le-classeur-backups'
scp /var/backup/le-classeur-offhost/*.dump* root@terraform:/root/le-classeur-backups/
```

Comparer les SHA-256 des dumps aux trois emplacements (les chemins contenus
dans `.sha256` sont ceux du CT ; vérifier les valeurs en adaptant le chemin).
Tester `pg_restore` sur une base jetable indépendante. Le timer et sa rétention
hors hôte doivent être déclarés après validation de ces accès et du stockage ;
ces commandes ne prouvent pas qu'une copie ou un timer existent déjà.

Le module `my-services.infra.classeur-backup.enable` reste désactivé par défaut.
Il déclare un timer sur **dev-nixos uniquement**, quotidien à 03:15, qui demande
un dump PostgreSQL vérifié au CT puis compare SHA-256 après chaque copie. Une
panne HTTP ne bloque pas la sauvegarde quand la base reste sauvegardable.
Les données sont transférées sous un nom temporaire et publiées sur le stockage
uniquement après comparaison. Il ne supprime aucune sauvegarde hors hôte ; une
rétention sera choisie après restauration testée et mesure du volume. Activer ce
module seulement après application saine et CI exacte de main, avec surveillance
de l'espace libre et des échecs de `le-classeur-offhost-backup.service`.

Pour rollback avant toute nouvelle écriture destination, remettre la release
et l'origine source gelée après contrôle. **Après** des écritures destination,
geler les deux côtés et effectuer une migration inverse vérifiée ; repointer
simplement DNS vers Neon perdrait les nouvelles opérations. Conserver Worker,
Neon, releases et sauvegardes jusqu'à validation de la période d'observation.
Aucune suppression cloud ni résiliation n'est couverte par cette migration.

## Raccordement GitOps

Après santé réelle, exécuter `provision.py register classeur`, récupérer
`identities/classeur.json` et le SOPS chiffré, puis proposer `gitops.enable = true`.
Le contrôleur GitOps et sa garde CI restent le seul parcours principal. Ne pas
activer `internalProxy` sans décider du traitement du préfixe `/classeur/` :
l'application utilise une origine et des routes racine. Beszel/Gatus sont dérivés
de la déclaration ; aucun inventaire parallèle ni IP recopiée dans les dashboards.

Contrôles locaux : tests Python, `git diff --check`, `nix fmt -- --check`, évaluation
et build du seul CT dans le checkout isolé du contrôleur. Pour la release, vérifier
types/build/tests de l'application, PostgreSQL réel et restore testé. Conserver
les mesures et distinguer les étapes préparées, créées, restaurées et activées.
