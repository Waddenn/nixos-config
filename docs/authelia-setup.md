# Configuration Authelia

## 🔧 Setup Initial

### 1. Générer les secrets

Authelia nécessite plusieurs secrets cryptographiques :

```bash
# Générer JWT secret (minimum 20 caractères)
openssl rand -base64 32 > /tmp/authelia_jwt_secret

# Générer storage encryption key (minimum 20 caractères)
openssl rand -base64 32 > /tmp/authelia_storage_encryption_key

# Si vous utilisez PostgreSQL, générer le mot de passe DB
openssl rand -base64 32 > /tmp/authelia_db_password
```

### 2. Ajouter les secrets à SOPS

Créez ou modifiez votre fichier de secrets :

```yaml
# secrets/authelia.env
authelia_jwt_secret=<contenu de /tmp/authelia_jwt_secret>
authelia_storage_encryption_key=<contenu de /tmp/authelia_storage_encryption_key>
# authelia_db_password=<si postgres>
```

Puis chiffrez avec SOPS :
```bash
sops -e secrets/authelia.env > secrets/authelia.env.enc
```

Ajoutez la référence dans le module si nécessaire.

### 3. Créer le fichier utilisateurs

Le fichier `users_database.yml` stocke les utilisateurs (mode file backend).

Exemple de structure :
```yaml
users:
  john:
    displayname: "John Doe"
    # Généré avec: authelia crypto hash generate argon2 --password 'votre-mot-de-passe'
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."
    email: john@example.com
    groups:
      - admins
      - dev

  jane:
    displayname: "Jane Smith"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."
    email: jane@example.com
    groups:
      - users
```

### 4. Générer un hash de mot de passe

```bash
# Installer authelia localement ou utiliser Docker
nix-shell -p authelia

# Générer le hash
authelia crypto hash generate argon2 --password 'MonMotDePasse123!'
```

Copiez le hash dans `users_database.yml`.

## 🔗 Intégration avec Caddy

### Configuration Caddy pour Forward Auth

Exemple pour protéger Gitea :

```caddyfile
gitea.hexaflare.net {
  tls {
    dns cloudflare {env.CF_API_TOKEN}
  }

  # Authelia forward auth
  forward_auth authelia:9091 {
    uri /api/authz/forward-auth
    copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
  }

  # Reverse proxy vers Gitea
  reverse_proxy http://192.168.40.112:3000
}

# Page de connexion Authelia
auth.hexaflare.net {
  tls {
    dns cloudflare {env.CF_API_TOKEN}
  }

  reverse_proxy http://authelia:9091
}
```

### Intégration dans le module Caddy

Dans `modules/services/networking/caddy.nix` :

```nix
virtualHosts = {
  "auth.hexaflare.net" = {
    extraConfig = commonConfig + ''
      reverse_proxy http://192.168.40.XXX:9091
    '';
  };

  "gitea.hexaflare.net" = {
    extraConfig = commonConfig + ''
      forward_auth http://192.168.40.XXX:9091 {
        uri /api/authz/forward-auth
        copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
      }

      reverse_proxy http://192.168.40.112:3000
    '';
  };
};
```

## 🎯 Règles d'accès courantes

### Bypass (accès public)
```nix
{
  domain = ["status.hexaflare.net"];
  policy = "bypass";
}
```

### One Factor (login + password)
```nix
{
  domain = ["*.hexaflare.net"];
  policy = "one_factor";
}
```

### Two Factor (2FA requis)
```nix
{
  domain = ["admin.hexaflare.net" "bitwarden.hexaflare.net"];
  policy = "two_factor";
}
```

### Par groupe d'utilisateurs
```nix
{
  domain = ["admin.hexaflare.net"];
  policy = "two_factor";
  subject = ["group:admins"];
}
```

### Par ressource (regex)
```nix
{
  domain = ["api.hexaflare.net"];
  policy = "bypass";
  resources = ["^/public/.*$"];
}
```

## 📊 Monitoring

Authelia expose des métriques Prometheus sur le port `9959` :

```nix
# Dans prometheus.nix
scrape_configs = [
  {
    job_name = "authelia";
    static_configs = [{
      targets = ["authelia:9959"];
    }];
  }
];
```

## 🔐 Configuration 2FA

Par défaut, Authelia supporte :
- **TOTP** (Google Authenticator, Authy, etc.)
- **WebAuthn** (YubiKey, passkeys)

Les utilisateurs peuvent configurer 2FA depuis l'interface web :
`https://auth.hexaflare.net`

## 🚀 Migration SQLite → PostgreSQL

Si vous voulez migrer vers PostgreSQL plus tard :

1. Modifier la config du host :
```nix
database = {
  type = "postgres";
  host = "localhost";  # ou IP du serveur PG
  port = 5432;
  name = "authelia";
  user = "authelia";
};
```

2. Le module créera automatiquement la base de données si locale

3. Redémarrer le service :
```bash
systemctl restart authelia
```

## 📝 Troubleshooting

### Vérifier les logs
```bash
journalctl -u authelia -f
```

### Tester la config
```bash
authelia validate-config --config /etc/authelia/configuration.yml
```

### Réinitialiser un utilisateur
Éditez `/var/lib/authelia/users_database.yml` et rechargez :
```bash
systemctl reload authelia
```
