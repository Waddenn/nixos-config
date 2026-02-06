# Guide SOPS-nix - Gestion des Secrets

Ce guide explique comment ajouter et gérer des secrets avec sops-nix dans cette infrastructure.

## 📋 Comprendre votre configuration actuelle

### Structure SOPS

Votre projet utilise **sops-nix** avec **age** encryption :

```
.sops.yaml           # Configuration SOPS (règles de chiffrement)
secrets/
├── secrets.yaml     # Secrets principaux (gh-token, discord-webhook, cf_api_token)
├── cf_api_token.env.enc  # Token Cloudflare (format .env)
└── authelia.env.example  # Template pour futurs secrets Authelia
```

### Clés age configurées

Votre [.sops.yaml](.sops.yaml) définit 4 clés age :

| Nom | Clé publique age | Usage |
|-----|------------------|-------|
| `primary` | `age10yfuvw...` | Clé principale |
| `caddy` | `age1t2s42a...` | Host Caddy |
| `github-runner` | `age1u5n52q...` | Host GitHub Runner |
| `dev-nixos` | `age13nxnv5...` | Machine de dev |

Ces clés sont générées depuis les **clés SSH ED25519** des hosts (`/etc/ssh/ssh_host_ed25519_key`).

## 🔐 Workflow : Ajouter des secrets

### Méthode 1 : Éditer secrets.yaml (recommandé pour secrets multiples)

#### 1. Éditer le fichier chiffré

```bash
# Ouvrir l'éditeur SOPS pour secrets.yaml
nix shell nixpkgs#sops --command sops secrets/secrets.yaml
```

Cela ouvrira votre `$EDITOR` avec le fichier **déchiffré**. Exemple :

```yaml
cf_api_token: xxxxxx
gh-token: ghp_xxxxx
discord-webhook: https://discord.com/api/webhooks/...

# Ajoutez vos nouveaux secrets ici :
authelia_jwt_secret: VOTRE_SECRET_ICI
authelia_storage_encryption_key: AUTRE_SECRET_ICI
```

#### 2. Sauvegarder et quitter

SOPS **re-chiffrera automatiquement** le fichier à la sauvegarde.

#### 3. Référencer dans NixOS

Dans votre module (ex: `authelia.nix`) :

```nix
sops.secrets.authelia_jwt_secret = {
  sopsFile = ../../secrets/secrets.yaml;  # Fichier source
  owner = "authelia";                      # Propriétaire du secret
  group = "authelia";
  mode = "0400";                           # Permissions
  restartUnits = ["authelia.service"];     # Services à redémarrer
};
```

Le secret sera déchiffré et placé dans : `/run/secrets/authelia_jwt_secret`

### Méthode 2 : Créer un fichier .env chiffré (recommandé pour groupes de secrets)

#### 1. Créer le fichier non chiffré

```bash
cat > secrets/authelia.env << 'EOF'
authelia_jwt_secret=GENEREZ_AVEC_OPENSSL_RAND
authelia_storage_encryption_key=AUTRE_SECRET_GENERE
authelia_db_password=MOT_DE_PASSE_DB
EOF
```

#### 2. Chiffrer avec SOPS

```bash
nix shell nixpkgs#sops --command sops -e secrets/authelia.env > secrets/authelia.env.enc
```

**Important** : Supprimez ensuite le fichier non chiffré !

```bash
rm secrets/authelia.env
```

#### 3. Référencer dans NixOS

```nix
sops.secrets.authelia_jwt_secret = {
  format = "dotenv";                       # Format .env
  sopsFile = ../../secrets/authelia.env.enc;
  owner = "authelia";
  # ...
};
```

SOPS extraira automatiquement la clé `authelia_jwt_secret` du fichier .env.

### Méthode 3 : Créer un nouveau fichier YAML

```bash
# Créer et éditer directement
nix shell nixpkgs#sops --command sops secrets/mon-service.yaml
```

SOPS créera un nouveau fichier chiffré selon les règles de `.sops.yaml`.

## 🔑 Générer de nouvelles clés age

### Pour un nouveau host

1. **Déployer le host** avec SSH activé (pour générer `/etc/ssh/ssh_host_ed25519_key`)

2. **Extraire la clé publique SSH** :
   ```bash
   ssh root@nouveau-host 'cat /etc/ssh/ssh_host_ed25519_key.pub'
   ```

3. **Convertir SSH → age** :
   ```bash
   nix shell nixpkgs#ssh-to-age --command sh -c 'ssh root@nouveau-host "cat /etc/ssh/ssh_host_ed25519_key.pub" | ssh-to-age'
   ```

   Sortie : `age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

4. **Ajouter dans `.sops.yaml`** :
   ```yaml
   keys:
     - &nouveau-host age1xxxxx...

   creation_rules:
     - path_regex: secrets/[^/]+\.(yaml|json|env|ini)(\.enc)?$
       key_groups:
       - age:
           - *primary
           - *nouveau-host  # <-- Ajoutez ici
   ```

5. **Re-chiffrer tous les secrets** existants pour le nouveau host :
   ```bash
   cd /home/tom/Dev/nixos-config
   nix shell nixpkgs#sops --command sops updatekeys -y secrets/secrets.yaml
   nix shell nixpkgs#sops --command sops updatekeys -y secrets/cf_api_token.env.enc
   ```

## 🎯 Cas pratique : Ajouter les secrets Authelia

### Option A : Utiliser secrets.yaml (tout au même endroit)

```bash
# 1. Générer les secrets
JWT_SECRET=$(openssl rand -base64 32)
STORAGE_KEY=$(openssl rand -base64 32)

# 2. Éditer secrets.yaml
nix shell nixpkgs#sops --command sops secrets/secrets.yaml

# 3. Ajouter ces lignes :
#    authelia_jwt_secret: <collez $JWT_SECRET>
#    authelia_storage_encryption_key: <collez $STORAGE_KEY>

# 4. Sauvegarder et quitter
```

**Puis modifier** `authelia.nix` :

```nix
sops.secrets = {
  authelia_jwt_secret = {
    sopsFile = ../../../secrets/secrets.yaml;  # Changé !
    owner = "authelia";
    # ...
  };
  authelia_storage_encryption_key = {
    sopsFile = ../../../secrets/secrets.yaml;  # Changé !
    # ...
  };
};
```

### Option B : Créer authelia.env.enc (séparé)

```bash
# 1. Créer le fichier
cat > secrets/authelia.env << EOF
authelia_jwt_secret=$(openssl rand -base64 32)
authelia_storage_encryption_key=$(openssl rand -base64 32)
EOF

# 2. Chiffrer
nix shell nixpkgs#sops --command sops -e secrets/authelia.env > secrets/authelia.env.enc

# 3. Supprimer le fichier non chiffré
rm secrets/authelia.env

# 4. Vérifier
nix shell nixpkgs#sops --command sops -d secrets/authelia.env.enc
```

Votre `authelia.nix` est déjà configuré pour cette méthode ✅

## 🛠 Commandes utiles

### Éditer un secret existant
```bash
nix shell nixpkgs#sops --command sops secrets/secrets.yaml
```

### Voir un secret déchiffré (sans l'éditer)
```bash
nix shell nixpkgs#sops --command sops -d secrets/secrets.yaml
```

### Ajouter une nouvelle clé à un fichier existant
```bash
# Éditer directement
nix shell nixpkgs#sops --command sops secrets/secrets.yaml
# Puis ajouter la ligne et sauvegarder
```

### Re-chiffrer après modification de .sops.yaml
```bash
nix shell nixpkgs#sops --command sops updatekeys secrets/secrets.yaml
```

### Vérifier quel(s) secret(s) peut déchiffrer un fichier
```bash
nix shell nixpkgs#sops --command sops -d --extract '["sops"]["age"]' secrets/secrets.yaml
```

## 📂 Où vont les secrets déchiffrés ?

Sur chaque host NixOS, `sops-nix` déchiffre les secrets au boot et les place dans :

```
/run/secrets/
├── authelia_jwt_secret           # Mode 0400, owner:authelia
├── authelia_storage_encryption_key
├── cf_api_token
├── gh-token
└── ...
```

Ces fichiers sont **temporaires** (tmpfs) et disparaissent au reboot.

## 🔒 Bonnes pratiques

1. **Ne commitez JAMAIS de secrets non chiffrés**
   - Ajoutez `secrets/*.env` à `.gitignore` (déjà fait ✅)
   - Seuls les fichiers `.enc` doivent être versionnés

2. **Utilisez des secrets aléatoires forts**
   ```bash
   openssl rand -base64 32  # Pour la plupart des secrets
   openssl rand -hex 32     # Format hexadécimal
   ```

3. **Principe du moindre privilège**
   - Donnez accès aux secrets uniquement aux hosts qui en ont besoin
   - Utilisez `owner` et `mode` pour restreindre l'accès

4. **Re-chiffrez après ajout d'un host**
   ```bash
   nix shell nixpkgs#sops --command sops updatekeys -y secrets/*.{yaml,enc}
   ```

5. **Testez le déchiffrement avant de déployer**
   ```bash
   nix shell nixpkgs#sops --command sops -d secrets/authelia.env.enc
   ```

## 🚨 Troubleshooting

### "no key could be found"
- Vérifiez que votre clé age est dans `.sops.yaml`
- Vérifiez que le fichier a été re-chiffré avec `sops updatekeys`

### "MAC mismatch" ou "failed to decrypt"
- Le fichier est corrompu ou la clé est incorrecte
- Restaurez depuis git : `git checkout secrets/fichier.enc`

### Le secret n'apparaît pas dans /run/secrets/
- Vérifiez les logs : `journalctl -u sops-nix`
- Le module sops-nix est-il importé ? (Oui, via `proxmox-lxc-config.nix`)
- Le service dépendant démarre-t-il après sops ? Ajoutez :
  ```nix
  systemd.services.authelia.after = ["sops-nix.service"];
  ```

## 📚 Ressources

- [Documentation officielle sops-nix](https://github.com/Mic92/sops-nix)
- [Format .sops.yaml](https://github.com/getsops/sops#211using-sopsyaml-conf-to-select-kms-pgp-and-age-for-new-files)
- [Guide age encryption](https://github.com/FiloSottile/age)
