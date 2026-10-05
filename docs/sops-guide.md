# SOPS + NixOS (ce dépôt)

Chaque service possède un fichier chiffré et un destinataire machine distinct.
Les clés personnelles `primary` (secours historique) et `workstation` (poste
d'administration vérifié) conservent l'accès à tous les fichiers.

| Fichier | Machine autorisée | Contenu |
| --- | --- | --- |
| `secrets/caddy.yaml` | `caddy` | Jeton Cloudflare pour les certificats DNS |
| `secrets/authelia.yaml` | `authelia` | Secrets de session, stockage, OIDC et graines des comptes |
| `secrets/immich.yaml` | `immich` | Secret du client OIDC Immich |
| `secrets/controller.yaml` | `dev-nixos` | Webhook de notification du contrôleur |
| `secrets/gatus.yaml` | `gatus` | Webhook de notification Gatus |
| `secrets/operator.yaml` | Aucune | Jetons GitHub/Cachix conservés pour l'administration |

Les jetons de `operator.yaml` ne sont consommés par aucun module NixOS actuel.
Le runner GitHub n'a accès à aucun de ces fichiers. La CI utilise ses propres
secrets GitHub, indépendants de SOPS. Le contrôleur évalue et construit les
systèmes sans devoir déchiffrer les secrets applicatifs : chaque cible les
déchiffre à l'activation avec sa propre clé SSH host.

Le fichier commun `secrets/secrets.yaml` et le `defaultSopsFile` partagé des LXC
ont été supprimés. Chaque déclaration doit fournir son `sopsFile`. Les services
déclarés dans `provisioning/` conservent leur fichier et leur politique propres.

## Modifier un secret

Choisir le fichier du service, puis l'ouvrir avec SOPS :

```bash
just secrets-edit secrets/caddy.yaml
```

Pour vérifier explicitement les destinataires après une modification de
`.sops.yaml`, mettre à jour uniquement le fichier concerné :

```bash
just secrets-rekey secrets/caddy.yaml
```

`updatekeys` met à jour les destinataires du fichier courant ; il ne supprime
aucune ancienne copie et ne révoque pas la valeur du secret. Ne pas élargir les
destinataires des autres services pour faciliter un déploiement.

## Ajouter une machine ou un service

Convertir la clé publique SSH host en destinataire age :

```bash
ssh root@<host> 'cat /etc/ssh/ssh_host_ed25519_key.pub' \
  | nix shell nixpkgs#ssh-to-age --command ssh-to-age
```

Ajouter son alias dans `.sops.yaml`, puis une règle exacte pour son seul fichier,
avant la règle de secours. Cette dernière autorise uniquement les clés
personnelles : un nouveau fichier n'accorde jamais implicitement l'accès à la
flotte. Adapter la matrice de sécurité dans `tests/test_sops_isolation.py`.

Déclarer le fichier dans le module :

```nix
sops.secrets.mon_secret = {
  sopsFile = ../../../secrets/mon-service.yaml;
  owner = "service-user";
  group = "service-group";
  mode = "0400";
  restartUnits = ["mon-service.service"];
};
```

Utiliser ensuite `config.sops.secrets.mon_secret.path`. Les valeurs et les
hashes de mots de passe ne doivent jamais être interpolés dans une dérivation
Nix ni affichés dans les logs de validation. Pour Authelia, suivre
[authelia-password-rotation.md](authelia-password-rotation.md) : sa base
persistante n'est pas remplacée par la graine SOPS lors des activations suivantes.

## Validation et mise en production

Avant publication, vérifier les destinataires des fichiers chiffrés, les règles
de création, les références Nix et l'absence de secrets en clair :

```bash
python3 -m unittest discover -s tests -p 'test_*.py'
nix fmt -- --check
```

Pour une migration de fichiers existants, comparer les valeurs déchiffrées en
mémoire sans les afficher. Vérifier aussi que chaque machine peut déchiffrer
son fichier et échoue sur les fichiers des autres services, en isolant les
identités de test. Ne pas charger les clés personnelles dans ce test machine.
Construire les systèmes concernés depuis un checkout isolé sur `dev-nixos`.

Suivre `AGENTS.md` : PR brouillon pendant les itérations, validations locales,
PR prête, fusion autorisée, CI verte du SHA exact de `main`, puis activation
autorisée et contrôle des secrets effectifs et de la santé des services.

## Limite des copies historiques et rotation

La séparation utilise de nouvelles clés de données SOPS et conserve les valeurs
pour éviter une interruption des applications. Elle limite le déchiffrement
des nouveaux fichiers, mais les anciennes copies du fichier commun restent
dans Git, les anciens systèmes Nix et les sauvegardes. Une ancienne clé machine
autorisée peut encore déchiffrer ces copies. Retirer un destinataire du fichier
courant ne suffit donc pas à invalider les anciens identifiants.

La fermeture de cette exposition historique exige une rotation coordonnée :

- Remplacer et révoquer les anciens jetons Cloudflare, GitHub et Cachix chez
  leurs fournisseurs, puis mettre à jour les fichiers et consommateurs concernés.
- Remplacer les webhooks Discord dans les deux fichiers et vérifier les deux
  services de notification.
- Renouveler le secret OIDC Immich et son digest côté Authelia ensemble, puis
  tester la connexion web et mobile.
- Renouveler les secrets de session/JWT et les clés de signature Authelia selon
  leur procédure de migration ; prévoir la réauthentification des utilisateurs.
- Migrer la clé de chiffrement du stockage avec l'outil Authelia prévu à cet
  effet et une sauvegarde vérifiée. Un simple remplacement casserait la lecture
  des données existantes, notamment les seconds facteurs.
- Changer les mots de passe dans la base Authelia persistante si les anciens
  hashes restent exploitables ; modifier les graines SOPS seules ne les change pas.

Les jetons GitHub/Cachix stockés dans SOPS et les credentials de la CI ou du
contrôleur doivent être inventoriés séparément avant révocation. Une purge de
l'historique Git ou un nettoyage des anciennes générations/sauvegardes n'est
pas un remplacement de cette rotation et demande une opération coordonnée.
