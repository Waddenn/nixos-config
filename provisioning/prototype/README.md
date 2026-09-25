> Archive du premier lot. Les commandes et fichiers exécutables ont été remplacés
> par le [parcours de services commun](../README.md).

# Prototype Proxmox — hors production

Ce lot crée **uniquement le CT jetable 9901 sur proxade**. Il ne déclare aucun
hôte dans `hosts/`, ne rejoint pas Tailscale et ne charge aucun secret SOPS.
Il ne modifie ni Colmena, ni le contrôleur GitOps, ni les garde-fous CI de main.

## Audit du 19 septembre 2026

Avant l'expérience : 19 LXC, trois VM ordinaires et un template VM dans Proxmox ;
14 déclarations NixOS actives. L'ancien state Telmate contient 22 LXC :

| Écart | État observé |
| --- | --- |
| Gotify 109, OnlyOffice 118, bourse-dashboard 119 | Dans l'ancien state, absents de Proxmox |
| calibre 110, dev-debian 124, hytale-server 206, github-runner 251, ai-controller 252 | Dans Proxmox, hors flotte NixOS active |
| valheim-server 204 / `hosts/valheim` | Alias à préserver lors d'une adoption |
| nextcloud-pgsql 116, hytale-server 206, terraform 253 | `target_node` vide dans le state ; réellement proxade, proxade, nuc-pve-1 |
| Ancien checkout Terraform | `74128c0`, distant observé `9776f0b` ; ne pas appliquer ce checkout périmé |
| Ancien state | Terraform 1.14.4, serial 508, daté du 8 février, mode 0644 ; ni modifié ni importé |
| Ancien jeton API | HTTP 401 lors de l'audit ; aucun renouvellement de ce jeton |

Proxade : PVE 9.2.18, environ 34 Gio de RAM disponible ; Storage2 environ
276 Gio disponibles lors du choix, contrôleur environ 13 Gio avant les builds.
9901 était libre dans tout le cluster. Réseau DHCP sur vmbr0 pour éviter de
choisir une adresse statique non réservée ; le prototype n'a aucun domaine.

## Choix et séparation des responsabilités

Terranix 2.9.0 génère le JSON ; OpenTofu 1.12.6 garde le graphe, le state et son
verrou ; bpg/proxmox 0.113.1 gère le LXC. Versions Nix et fournisseur verrouillées
ici, indépendamment de la flake de production. Ce n'est pas une migration du
state Telmate. Les petits scripts ne remplacent pas OpenTofu : construction et
upload d'une image NixOS standard, puis validation restrictive de son plan.

La future déclaration commune pourra alimenter ces ressources et les modules
NixOS/Colmena. Avant un pilote : décider la gestion des IP, prévoir l'ajout de la
clé hôte SSH à SOPS, l'enrôlement Tailscale, puis application/domaine/supervision.
Les secrets ne doivent pas entrer dans les arguments de build ou le Nix store.
L'activation de production restera soumise à la CI GitHub du SHA exact de main,
aux canaris et aux contrôles de santé et d'espace depuis dev-nixos.

### Résultat du diagnostic bootstrap

L'ancienne image `nixos-image-lxc-base-proxmox-25.05-x86_64-linux.tar.xz` ne
termine pas son activation sans nesting : `run-wrappers.mount` échoue et
`/run/current-system` manque. Nesting corrige ce problème, mais l'image n'active
pas sshd. `bootstrap.nix` construit donc une image minimale SSH prête à démarrer,
sans les modules de production qui dépendent de SOPS/Tailscale.

Avec bpg 0.113.1, **modifier** features émet également les booléens false ; PVE
refuse cela avec un jeton, même root@pam à privilèges séparés. Le test root a été
révoqué. La création utilise une autre branche du fournisseur, qui omet ces
booléens : nesting doit être déclaré dès la création. Ne pas généraliser une
identité root ou ignorer silencieusement cette dérive pour corriger une mise à
jour. Le script refuse les mises à jour ; leur prise en charge est un lot futur.

## Préparation sur dev-nixos

Tous les builds et les appels OpenTofu/upload s'exécutent comme root sur
**dev-nixos**, dans une copie isolée de ce dossier. Aucun cron n'est installé.

L'administrateur crée le compte `nixos-prototype@pve` et son jeton `controller`
(privsep=0, dont les droits restent ceux de cet utilisateur dédié) :

- `/` : rôle personnalisé `NixPrototypeAudit`, **Sys.Audit seulement** ;
- `/vms/9901` : PVEVMAdmin ; aucun droit VM sur les autres identifiants ;
- `/storage/Storage2` et `/storage/local` : PVEDatastoreUser ;
- `/storage/local` : rôle `NixPrototypeTemplates`, Datastore.AllocateTemplate ;
- `/sdn/zones/localnetwork/vmbr0` : PVESDNUser.

Le droit d'upload porte sur le stockage, pas sur un seul fichier. Les noms
adressés par SHA évitent les écrasements de templates. L'accès Sys.Audit permet
la découverte des nœuds. Vérifier les droits effectifs avec `pveum user token
permissions`, notamment `/vms/205` qui ne doit avoir aucun droit VM.

Créer `/var/lib/proxmox-prototype` et `backups/`, root:root mode 0700. Fournir
`api-token` mode 0600, au format `utilisateur!jeton=secret`, sans l'afficher.
Copier `pve-ca.pem` depuis `/etc/pve/pve-root-ca.pem` par un canal SSH authentifié.
Le fournisseur et curl vérifient cette CA et le nom `proxade` ; pas de TLS insecure.

Depuis la copie du dossier :

```sh
nix develop -c bash prepare-image.sh
nix develop -c bash run.sh plan
nix develop -c bash run.sh apply
nix develop -c bash run.sh plan
```

`prepare-image.sh` conserve la clé SSH privée dans le dossier d'état. Il ne la
régénère pas si elle existe. L'image ne contient que sa clé publique. Il écrit
`bootstrap.auto.tfvars.json` avec **ssh_public_key et template_file_id**, chargé
automatiquement par OpenTofu dans ce dossier. Le template porte son SHA-256 dans
son nom. La clé publique est aussi injectée via le fournisseur.

`run.sh` ne reçoit pas un plan extérieur : il reconstruit, valide et applique le
même plan sauvegardé, sous flock. Le state local a aussi le verrou natif OpenTofu.
Il copie le lock fournisseur versionné et utilise `init -lockfile=readonly`.
Les sauvegardes avant/après une opération sont mode 0600 dans `backups/`.
Le lanceur exporte aussi state, tfvars, clé SSH et jeton par SSH authentifié vers
`root@terraform:/root/proxmox-prototype-backups/` (nœud physique nuc-pve-1),
dossier 0700 et archives 0600. Cet hôte ne fait que stocker les sauvegardes ;
il ne lance pas OpenTofu. Un échec de sauvegarde avant opération bloque le lanceur.
Cette destination fait encore partie du même cluster : une sauvegarde hors
cluster sera nécessaire avant usage en production. Ne jamais committer
state, plans, clés, jetons ou tfvars. Le lock fournisseur est public et versionné.

## Reprise et protections

Après une interruption, attendre la fin éventuelle de la tâche PVE et vérifier
9901, son hostname, son tag, son disque et le state. Relancer `plan`, puis
`apply` uniquement si le plan accepté est création/no-op. Si le state manque
alors que le CT existe, **ne pas recréer** : restaurer une sauvegarde vérifiée
sous le verrou, puis rafraîchir avec un plan. Sans sauvegarde, une procédure
d'import séparée doit conserver les champs de création non lisibles par l'API ;
un plan de remplacement n'est jamais une procédure d'adoption acceptable.

Le script rejette toute suppression, remplacement, mise à jour, autre adresse
ou autre identité. `prevent_destroy` protège tant que la déclaration existe ;
il ne protège pas une déclaration retirée. Le contrôle du JSON du plan couvre
ce retrait. Le flag PVE `protection=1` est une dernière barrière indépendante.
Il n'existe pas de commande destroy dans le lanceur. Le nettoyage du jetable
exige une opération explicite et vérifiée, pas le retrait d'une déclaration.

Pour une future adoption : sauvegarder state et données, figer l'ancien moteur,
retirer la propriété dans son state **sans destruction**, importer dans le
nouveau, puis exiger un plan sans changement. Aucun import de la flotte n'a lieu
ici. Ne jamais conserver deux moteurs actifs sur la même ressource.

## Validation

Voir `validation.md` pour les résultats réellement observés et les limites.

Sources : [Terranix/OpenTofu](https://terranix.org/docs/what-is-terranix/),
[fournisseur LXC](https://github.com/bpg/terraform-provider-proxmox/blob/v0.113.1/docs/resources/virtual_environment_container.md),
[implémentation des features](https://github.com/bpg/terraform-provider-proxmox/blob/v0.113.1/proxmoxtf/resource/container/container.go),
[state OpenTofu](https://opentofu.org/docs/language/state/).
