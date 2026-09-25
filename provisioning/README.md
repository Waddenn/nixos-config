# Un service, une déclaration

`services.nix` est la source commune des identités, ressources Proxmox,
configuration NixOS, application, contrôles HTTP et supervision. Deux services
ont été créés : `prototype` (CT 9901) et `probe` (CT 9902).

- `gitops.enable = false` : amorçage et activation dans le flake isolé.
- `gitops.enable = true` : nœud du flake principal, activation exclusivement par
  le GitOps existant après CI réussie sur le SHA exact de main et canaris.

`probe` est proposé pour ce raccordement ; les changements centraux de cette
branche ne sont pas encore activés. L'application reste une sonde interne de
validation, pas un service métier. `prototype` reste hors du timer de production.
Voir le [plan de raccordement et ses prérequis](ACTIVATION.md).

## Ajouter un service pilote

1. Ajouter une entrée dans `services.nix` : nom/hostname et VMID uniques, nœud,
   stockage, ressources et module applicatif. L'exemple `prototype` contient le
   contrat complet : port, chemin et corps HTTP attendus, unités, conditions
   Gatus et noms des secrets à générer. Un autre module NixOS peut remplacer
   `applications/demo.nix` sans modifier les inventaires réseau ou supervision.
   Commencer avec `gitops.enable = false` (valeur par défaut).
2. Copier ce dossier sur **dev-nixos**, dans une copie isolée. Ne pas écraser
   son checkout GitOps. Depuis cette copie :

   ```sh
   nix develop -c python3 provision.py up NOM_DU_SERVICE
   ```

   Le parcours est : capacité et propriété → ACL limitées → image SSH → plan
   protégé/création → découverte IP et clé hôte → SOPS → Colmena → santé/Gatus
   → enrôlement OAuth Tailscale → HTTP et SSH sur le réseau Tailscale.

3. Récupérer le **fichier chiffré** `secrets/NOM_DU_SERVICE.yaml` créé sur le
   contrôleur dans le dépôt avant publication. Les secrets applicatifs qui ne
   sont pas des valeurs aléatoires générables doivent être chiffrés/préparés
   explicitement ; ne pas mettre de valeurs secrètes dans la déclaration Nix.

Le même nom Nix produit l'adresse Terraform, l'alias SSH et le nœud Colmena.
Les adresses DHCP/Tailscale et clés publiques sont des faits observés, écrits
par `discover` dans `runtime-public.json` (non versionné), pas un second inventaire
à maintenir. Ne pas recopier une adresse dans Gatus, Beszel ou un fichier hosts.
Les doublons de VMID/hostname échouent à l'évaluation.

## Ce qui est automatisé et ce qui reste préalable

Une fois configurés, les accès du contrôleur servent aux services suivants :

- compte API PVE dédié et CA vérifiée, plus SSH administrateur vers les nœuds
  Proxmox avec clés hôtes préalablement authentifiées ;
- rôles PVE `NixPrototypeAudit` (Sys.Audit), `NixPrototypeTemplates`
  (Datastore.AllocateTemplate), PVEVMAdmin/PVEDatastoreUser/PVESDNUser standards ;
- client OAuth Tailscale `auth_keys`, limité à `tag:nixos-pilot`, fichier
  `tailscale-oauth.json` root:root 0600 dans le dossier d'état ;
- accès SSH au stockage de sauvegarde sur `terraform`/nuc-pve-1.

`authorize` interroge réellement le cluster avant d'accorder les droits du compte
API pour **le nouvel ID déclaré**, ses stockages et son bridge. Il refuse toute
adoption implicite d'un conteneur existant. Le compte API ne reçoit pas de droits
VM sur tout le cluster. L'étape utilise le SSH administrateur déjà autorisé sur
le contrôleur ; les appels OpenTofu continuent à utiliser le jeton limité.
Un nouveau nœud physique demande une initialisation de confiance SSH, pas un
`ssh-keyscan` accepté aveuglément. `local` reste le stockage de templates et
`localnetwork` la zone SDN pris en charge par ce lot.

L'[accès OAuth et sa rotation](TAILSCALE-ACCESS.md) sont décrits séparément.
Aucune clé d'enrôlement manuelle n'est requise par service. La clé OAuth durable
reste sur le contrôleur ; le CT ne reçoit qu'une clé à usage unique valable une
heure, via SSH puis un fichier temporaire dans `/run`.

## Amorçage et application

L'image NixOS minimale ne dépend ni de Tailscale ni de SOPS. Une clé SSH dédiée
est générée sur le contrôleur, seule sa partie publique entre dans l'image.
Le nom de template contient son SHA-256. Les images existantes sont conservées ;
un changement d'image qui imposerait de recréer le CT est refusé par le plan.
`nesting` est défini dès la création pour éviter le problème de modification des
features de bpg/Proxmox documenté dans l'audit du premier lot.

La découverte lit l'adresse via l'API Proxmox et obtient la clé SSH hôte via
`pct exec` sur le canal administrateur authentifié. Une clé hôte changée bloque
l'opération. Les secrets SOPS sont chiffrés pour cette clé hôte et celle du
contrôleur. Colmena déploie ensuite le système par SSH LAN ; le pilote n'est
jamais obligé de posséder déjà Tailscale pour recevoir son secret/configuration.
Après enrôlement, l'alias SSH utilise l'adresse Tailscale avec la même clé hôte.

La démo ne constitue pas une application métier : réponse HTTP simple,
`/healthz` et `/private` authentifié par secret SOPS. Le secret est transmis à
l'unité par `LoadCredential`, pas par variable Nix ou ligne de commande. Un
Gatus local sur `127.0.0.1:8081` contrôle l'application toutes les cinq secondes.
La santé exige une mesure Gatus réussie et récente. Les pilotes isolés n'affectent pas les inventaires centraux. Le raccordement
GitOps génère automatiquement l'agent Beszel, les endpoints Gatus direct/proxy
et une route Caddy interne. Aucun enregistrement DNS public n'est nécessaire.

## Proposer le raccordement GitOps

Après un `up` complet et sain, exécuter sur le contrôleur :

```sh
nix develop -c python3 provision.py register NOM_DU_SERVICE
```

Cette commande vérifie l'accès de l'utilisateur GitOps `nixos`, avec sa clé
existante. Elle épingle la clé hôte précédemment obtenue via Proxmox (aucun
keyscan aveugle) et produit `identities/NOM_DU_SERVICE.json`, **clés publiques
uniquement**. Récupérer cet artefact généré avec le secret SOPS chiffré dans Git,
puis renseigner `gitops = { enable = true; canary = true; internalProxy = true; };`
dans la même déclaration. `canary` et `internalProxy` sont des choix explicites.
L'identité publiée ne peut pas être remplacée automatiquement.

Le flake principal dérive le nœud NixOS/Colmena, sa politique de santé et les
consommateurs centraux. Beszel découvre le nœud via `nixosConfigurations` ;
aucune nouvelle ligne dans `modules/data/beszel-hosts.nix`. Le hostname Tailscale
sert aux connexions : aucune IP DHCP/Tailscale recopiée dans la déclaration.
Les versions Nixpkgs/SOPS du flake principal deviennent alors la référence.

`up`/`deploy` du provisionneur refusent un service marqué GitOps ; il disparaît
également du hive isolé. Ce passage prépare une PR, il n'active rien de central.
Les commandes `plan`, `discover`, `health` et `enroll` restent disponibles pour
l'état d'infrastructure et le diagnostic. Le timer existant reste le seul chemin
d'activation régulier, avec ses garde CI, canaris, capacité et générations.

La route interne proposée est
`http://caddy.salamander-scala.ts.net:8085/NOM_DU_SERVICE/`.
Caddy n'autorise que les sources Tailscale `100.64.0.0/10` et le firewall ouvre
8085 uniquement sur `tailscale0`. Le nom vient du MagicDNS existant ; aucun
DNS public, certificat public ou Funnel ajouté. Ce proxy HTTP est destiné à la
validation dans le réseau chiffré Tailscale. Un domaine public ou une application
métier demandera un choix d'accès et d'authentification adapté.

## État, reprise et retrait

Le chemin d'état historique `/var/lib/proxmox-prototype` est conservé pour ne
pas perdre la propriété Terraform. Un `flock` couvre le parcours ; OpenTofu
conserve aussi son verrou natif. Les clés, tfvars, diagnostics et états sont
root-only. Avant/après opération, une archive privée est sauvegardée localement
et sur `root@terraform:/root/proxmox-prototype-backups/` (autre nœud physique).
Cet hôte stocke les sauvegardes, il n'exécute pas le provisionnement.
Une sauvegarde hors cluster reste à prévoir avant production.

Les étapes des services encore isolés peuvent être relancées explicitement :

```sh
nix develop -c python3 provision.py plan prototype
nix develop -c python3 provision.py discover prototype
nix develop -c python3 provision.py deploy prototype
nix develop -c python3 provision.py health prototype
nix develop -c python3 provision.py enroll prototype
```

`hosts/NOM/last-run.json` enregistre étapes terminées, étape en cours et échec.
Après échec, le CT et ses données restent présents ; `up` reprend par
réconciliation. L'enrôlement vérifie d'abord l'identité déjà inscrite et ne
consomme pas une nouvelle clé si elle est correcte. Un échec de santé n'est pas
rapporté comme un succès global.

Le plan permet création/no-op uniquement. Mise à jour d'infrastructure,
remplacement, suppression et ressource disparue hors OpenTofu sont bloqués.
Une déclaration retirée ne permet pas de supprimer le CT. Utiliser
`lifecycle = "retained"` pour garder la ressource et exclure l'activation ; cela
ne stoppe pas les services existants. Pour un service GitOps, garder aussi son
bloc `gitops` : le nœud reste déclaré et son identité Beszel est conservée. Un CT retenu absent ne sera pas recréé.
Les opérations de destruction/adoption demandent une procédure distincte ;
aucune commande destroy ni import automatique n'est fournie.

Le test de restauration couvre une perte du fichier state avec sauvegarde
valide. Il ne prouve pas la reprise d'un crash PVE pendant extraction du disque.
Sans sauvegarde, ne pas importer puis accepter un remplacement : l'origine du
template n'est pas entièrement reconstituable depuis l'API.

## Validation

- `python3 -m unittest discover -s tests -p 'test_*.py'` depuis la racine du dépôt.
- `nix build ./provisioning#checks.x86_64-linux.single-declaration --no-link` :
  doublons refusés, mêmes identités Terraform/NixOS, endpoints dérivés du même port.
- `nix fmt -- --check` depuis la racine, dans une copie isolée si nécessaire.
- [Deuxième service et intégration](validation-integration.md),
  [premier pilote applicatif](validation.md).
- [Audit initial Proxmox/Telmate](prototype/README.md) et
  [tests du premier lot](prototype/validation.md) : historiques, commandes remplacées.
