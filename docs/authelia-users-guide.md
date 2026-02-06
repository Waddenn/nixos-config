# Guide de gestion des utilisateurs Authelia

Ce guide explique comment créer et gérer les utilisateurs Authelia.

## 🚀 Initialisation (première fois)

### Option A : Script automatisé (recommandé)

```bash
# Créer l'utilisateur admin et initialiser users_database.yml
just authelia-init-users

# Le script va :
# 1. Demander les infos de l'admin (username, email, password)
# 2. Générer le hash du mot de passe
# 3. Créer le fichier users_database.yml
# 4. Le déployer sur le serveur authelia
# 5. Configurer les permissions correctes
```

### Option B : Manuelle

```bash
# 1. Se connecter au serveur
just authelia-ssh

# 2. Créer le fichier
cat > /var/lib/authelia/users_database.yml << 'EOF'
users:
  admin:
    displayname: "Administrator"
    password: "$argon2id$v=19$m=65536,t=3,p=4$VOTRE_HASH_ICI"
    email: admin@hexaflare.net
    groups:
      - admins
      - users
EOF

# 3. Corriger les permissions
chown authelia:authelia /var/lib/authelia/users_database.yml
chmod 600 /var/lib/authelia/users_database.yml
```

## 👤 Ajouter un nouvel utilisateur

### Méthode 1 : Script interactif

```bash
# Lancer le script de création
just authelia-create-user

# Il va demander :
# - Nom d'utilisateur
# - Nom d'affichage
# - Email
# - Groupes
# - Mot de passe

# Puis afficher la configuration YAML à ajouter
```

### Méthode 2 : Ligne de commande

```bash
./scripts/authelia-create-user.sh john "John Doe" "john@example.com" "users,family"
```

### Méthode 3 : Directement sur le serveur

```bash
# 1. Générer le hash localement
just authelia-hash-password
# Copiez le hash généré

# 2. SSH sur le serveur
just authelia-ssh

# 3. Éditez le fichier
nano /var/lib/authelia/users_database.yml

# 4. Ajoutez l'utilisateur
users:
  john:
    displayname: "John Doe"
    password: "<hash_copié>"
    email: john@example.com
    groups:
      - users

# 5. Sauvegarder (Ctrl+O, Ctrl+X)
# Le fichier est rechargé automatiquement (watch: true)
```

## 👥 Groupes disponibles

Vous pouvez créer les groupes que vous voulez. Exemples courants :

| Groupe | Usage recommandé |
|--------|------------------|
| `admins` | Administrateurs - accès complet |
| `users` | Utilisateurs standards |
| `dev` | Développeurs - accès Gitea, etc. |
| `family` | Famille - accès médias (Immich, Jellyseerr) |
| `monitoring` | Accès aux outils de monitoring |
| `readonly` | Accès lecture seule |

### Utilisation dans les règles d'accès

```nix
# Dans hosts/authelia/default.nix
accessControlRules = [
  # Réservé aux admins
  {
    domain = ["grafana.hexaflare.net"];
    policy = "two_factor";
    subject = ["group:admins"];
  }

  # Admins et devs
  {
    domain = ["gitea.hexaflare.net"];
    policy = "one_factor";
    subject = ["group:admins" "group:dev"];
  }

  # Tout le monde authentifié
  {
    domain = ["immich.hexaflare.net"];
    policy = "one_factor";
  }
];
```

## 🔐 Gestion des mots de passe

### Générer un hash

```bash
# Méthode 1 : Script interactif
just authelia-hash-password

# Méthode 2 : Directement avec authelia
nix shell nixpkgs#authelia --command \
  authelia crypto hash generate argon2 --password 'VotreMotDePasse'
```

### Réinitialiser un mot de passe

```bash
# 1. Générer un nouveau hash
just authelia-hash-password

# 2. SSH sur le serveur
just authelia-ssh

# 3. Éditez users_database.yml
nano /var/lib/authelia/users_database.yml

# 4. Remplacez l'ancien hash par le nouveau
# 5. Sauvegarder - rechargement automatique
```

## 📋 Structure complète du fichier users_database.yml

```yaml
###############################################################
#                Authelia Users Database                      #
###############################################################

users:
  # Administrateur principal
  admin:
    displayname: "Administrator"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."
    email: admin@hexaflare.net
    groups:
      - admins
      - users

  # Développeur
  john:
    displayname: "John Doe"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."
    email: john@example.com
    groups:
      - dev
      - users

  # Utilisateur famille (lecture seule)
  marie:
    displayname: "Marie"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."
    email: marie@example.com
    groups:
      - family
      - readonly

  # Compte monitoring (sans shell)
  monitoring:
    displayname: "Monitoring Bot"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."
    email: monitoring@example.com
    groups:
      - monitoring
```

## 🛠 Commandes utiles

```bash
# Voir le fichier utilisateurs actuel
just authelia-ssh
cat /var/lib/authelia/users_database.yml

# Vérifier les logs Authelia
just authelia-ssh
journalctl -u authelia -f

# Redémarrer Authelia (si watch ne fonctionne pas)
just authelia-ssh
systemctl restart authelia

# Tester une authentification
curl -I https://gitea.hexaflare.net
# Devrait rediriger vers auth.hexaflare.net si non authentifié
```

## 🔍 Troubleshooting

### Le fichier n'est pas rechargé automatiquement

```bash
# Redémarrer le service
systemctl restart authelia

# Ou recharger la config
systemctl reload authelia
```

### Erreur "invalid password hash"

Le hash doit :
- Commencer par `$argon2id$`
- Être échappé avec des guillemets doubles dans YAML : `password: "$argon2id$..."`
- Ne PAS contenir d'espaces ou retours à la ligne

### Impossible de se connecter avec un nouvel utilisateur

1. Vérifiez les logs : `journalctl -u authelia -f`
2. Vérifiez que le fichier a les bonnes permissions : `ls -la /var/lib/authelia/users_database.yml`
3. Vérifiez la syntaxe YAML (indentation correcte)
4. Redémarrez Authelia : `systemctl restart authelia`

### L'utilisateur se connecte mais n'a pas accès

Vérifiez les règles d'accès dans [hosts/authelia/default.nix](../hosts/authelia/default.nix) :
- Le domaine est-il dans les règles ?
- L'utilisateur est-il dans les bons groupes ?
- La policy correspond-elle ? (one_factor vs two_factor)

## 🔄 Workflow complet

```bash
# 1. Déployer Authelia (avec secrets configurés)
just deploy

# 2. Initialiser le premier utilisateur admin
just authelia-init-users

# 3. Se connecter à l'interface web
# https://auth.hexaflare.net

# 4. (Optionnel) Configurer 2FA pour l'admin
# Via l'interface web

# 5. Créer d'autres utilisateurs
just authelia-create-user

# 6. SSH et ajouter au fichier
just authelia-ssh
nano /var/lib/authelia/users_database.yml

# 7. Tester l'authentification
curl -I https://gitea.hexaflare.net
```

## 📚 Ressources

- [Documentation Authelia - File Backend](https://www.authelia.com/configuration/first-factor/file/)
- [Authelia Access Control Rules](https://www.authelia.com/configuration/security/access-control/)
- [Guide principal Authelia](./authelia-setup.md)
- [Intégration Caddy](../examples/authelia-caddy-integration.md)
