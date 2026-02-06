# Intégration Authelia + Caddy

Ce document montre comment protéger vos services avec Authelia via Caddy.

## Configuration de base dans modules/services/networking/caddy.nix

### 1. Ajouter le domaine Authelia

```nix
virtualHosts = {
  # Interface Authelia
  "auth.hexaflare.net" = {
    extraConfig = commonConfig + ''
      reverse_proxy http://192.168.40.XXX:9091
    '';
  };

  # ... vos autres services
};
```

**Remplacez `192.168.40.XXX`** par l'IP de votre LXC Authelia.

## 2. Protéger vos services

### Gitea (authentification obligatoire)

```nix
"gitea.hexaflare.net" = {
  extraConfig = commonConfig + ''
    # Forward auth vers Authelia
    forward_auth http://192.168.40.XXX:9091 {
      uri /api/authz/forward-auth
      copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
    }

    # Proxy vers Gitea
    reverse_proxy http://192.168.40.112:3000
  '';
};
```

### Nextcloud (2FA pour admins uniquement)

```nix
# Dans hosts/authelia/default.nix, ajoutez:
accessControlRules = [
  # Admin avec 2FA
  {
    domain = ["nextcloud.hexaflare.net"];
    policy = "two_factor";
    subject = ["group:admins"];
  }
  # Utilisateurs normaux avec login simple
  {
    domain = ["nextcloud.hexaflare.net"];
    policy = "one_factor";
  }
];
```

```nix
# Dans caddy.nix:
"nextcloud.hexaflare.net" = {
  extraConfig = commonConfig + ''
    forward_auth http://192.168.40.XXX:9091 {
      uri /api/authz/forward-auth
      copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
    }

    reverse_proxy http://192.168.40.116:80
  '';
};
```

### Vaultwarden (2FA requis)

```nix
# Dans hosts/authelia/default.nix:
accessControlRules = [
  {
    domain = ["bitwarden.hexaflare.net"];
    policy = "two_factor";  # Force 2FA
  }
];
```

```nix
# Dans caddy.nix:
"bitwarden.hexaflare.net" = {
  extraConfig = commonConfig + ''
    forward_auth http://192.168.40.XXX:9091 {
      uri /api/authz/forward-auth
      copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
    }

    reverse_proxy http://192.168.30.113:8222
  '';
};
```

### Service public (sans authentification)

```nix
# Dans hosts/authelia/default.nix:
accessControlRules = [
  {
    domain = ["status.hexaflare.net"];
    policy = "bypass";  # Accès public
  }
];
```

### Service avec chemins publics et privés

```nix
# API publique mais admin protégé
accessControlRules = [
  # Bypass pour /api/public/*
  {
    domain = ["api.hexaflare.net"];
    policy = "bypass";
    resources = ["^/public/.*$"];
  }
  # Authentification pour le reste
  {
    domain = ["api.hexaflare.net"];
    policy = "one_factor";
  }
];
```

## 3. Services par groupe d'utilisateurs

### Grafana (réservé au groupe "admins")

```nix
accessControlRules = [
  {
    domain = ["grafana.hexaflare.net"];
    policy = "one_factor";
    subject = ["group:admins" "group:monitoring"];
  }
];
```

### Jellyseerr (famille uniquement)

```nix
accessControlRules = [
  {
    domain = ["jellyseerr.hexaflare.net"];
    policy = "one_factor";
    subject = ["group:family" "group:admins"];
  }
];
```

## 4. Protection par réseau (Tailscale)

```nix
accessControlRules = [
  # Bypass si connecté via Tailscale (100.64.0.0/10)
  {
    domain = ["internal.hexaflare.net"];
    policy = "bypass";
    networks = ["100.64.0.0/10"];
  }
  # Sinon authentification requise
  {
    domain = ["internal.hexaflare.net"];
    policy = "two_factor";
  }
];
```

## 5. Configuration complète exemple

```nix
# hosts/authelia/default.nix
{...}: {
  profiles.lxc-base.enable = true;

  my-services.auth.authelia = {
    enable = true;
    domain = "hexaflare.net";
    defaultPolicy = "deny";  # Deny par défaut

    accessControlRules = [
      # Services publics
      {
        domain = ["status.hexaflare.net"];
        policy = "bypass";
      }

      # Services famille (1FA)
      {
        domain = [
          "immich.hexaflare.net"
          "jellyseerr.hexaflare.net"
        ];
        policy = "one_factor";
        subject = ["group:family" "group:admins"];
      }

      # Services admin (2FA obligatoire)
      {
        domain = [
          "gitea.hexaflare.net"
          "grafana.hexaflare.net"
          "nextcloud.hexaflare.net"
        ];
        policy = "two_factor";
        subject = ["group:admins"];
      }

      # Vaultwarden (2FA pour tous)
      {
        domain = ["bitwarden.hexaflare.net"];
        policy = "two_factor";
      }

      # Développement (devs et admins)
      {
        domain = ["dev.hexaflare.net"];
        policy = "one_factor";
        subject = ["group:dev" "group:admins"];
      }
    ];
  };

  my-services.infra.deployment-target.enable = true;
  networking.firewall.allowedTCPPorts = [9091];
}
```

## 6. Tester la configuration

1. **Vérifiez qu'Authelia est accessible:**
   ```bash
   curl http://192.168.40.XXX:9091/api/health
   ```

2. **Testez un service protégé:**
   ```bash
   curl -I https://gitea.hexaflare.net
   # Devrait retourner 302 redirect vers auth.hexaflare.net
   ```

3. **Vérifiez les logs:**
   ```bash
   ssh authelia
   journalctl -u authelia -f
   ```

## 7. Headers disponibles

Authelia envoie ces headers à vos applications :

- `Remote-User`: nom d'utilisateur
- `Remote-Groups`: groupes (séparés par virgule)
- `Remote-Name`: nom d'affichage
- `Remote-Email`: email

Exemple d'utilisation dans votre app :
```python
# Flask example
@app.route('/profile')
def profile():
    username = request.headers.get('Remote-User')
    groups = request.headers.get('Remote-Groups', '').split(',')
    return f"Hello {username}, groups: {groups}"
```

## 8. Débogage

### Voir les règles actives
```bash
# Depuis le serveur Authelia
cat /etc/authelia/configuration.yml | grep -A 50 "access_control"
```

### Tester une règle spécifique
Authelia logs indiquent quelle règle s'applique :
```bash
journalctl -u authelia -f | grep "Access Control"
```

### Règle ne fonctionne pas ?
1. Vérifiez l'ordre (première règle qui match gagne)
2. Vérifiez la regex des resources
3. Vérifiez le nom du domaine (doit matcher exactement)
4. Redémarrez Authelia : `systemctl restart authelia`
