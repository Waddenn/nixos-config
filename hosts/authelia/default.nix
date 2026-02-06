# ============================================================================
# CONFIGURATION AUTHELIA
# ============================================================================
#
# Ce fichier configure Authelia pour l'authentification et l'autorisation.
#
# DOCUMENTATION:
# - Guide setup: docs/authelia-setup.md
# - Guide utilisateurs: docs/authelia-users-guide.md
# - Bonnes pratiques: Voir commentaires ci-dessous
#
# ORDRE D'ÉVALUATION DES RÈGLES:
# Les règles sont évaluées dans l'ordre (top → bottom).
# La PREMIÈRE règle qui correspond est appliquée.
# ⚠️ IMPORTANT: Placez les règles les plus spécifiques en premier !
#
# POLITIQUES DISPONIBLES:
# - bypass      : Aucune authentification (public)
# - one_factor  : Mot de passe uniquement
# - two_factor  : Mot de passe + TOTP (2FA)
# - deny        : Accès bloqué
#
# ============================================================================

{...}: {
  profiles.lxc-base.enable = true;

  my-services.auth.authelia = {
    enable = true;
    domain = "hexaflare.net";
    port = 9091;

    # ========================================================================
    # BASE DE DONNÉES
    # ========================================================================
    # SQLite : Simple, pas de dépendances (recommandé pour homelab)
    # PostgreSQL : Plus robuste, pour production avec beaucoup d'utilisateurs
    database.type = "sqlite"; # ou "postgres"

    # ========================================================================
    # REDIS (Stockage des sessions)
    # ========================================================================
    redis = {
      host = "localhost";
      port = 6379;
    };

    # ========================================================================
    # POLITIQUE PAR DÉFAUT
    # ========================================================================
    # deny       : Tout est bloqué sauf règles explicites (RECOMMANDÉ)
    # one_factor : 1FA par défaut (moins sécurisé)
    # two_factor : 2FA par défaut (très sécurisé mais peut être contraignant)
    defaultPolicy = "deny";

    # ========================================================================
    # RÈGLES D'ACCÈS
    # ========================================================================
    # ⚠️ ORDRE IMPORTANT : Première règle qui match = règle appliquée
    # Structure recommandée :
    #   1. BYPASS (services publics)
    #   2. TWO_FACTOR (services critiques)
    #   3. ONE_FACTOR (services standards)
    #   4. DENY (catch-all si defaultPolicy != deny)
    # ========================================================================

    accessControlRules = [
      # ======================================================================
      # 1. SERVICES PUBLICS (bypass - aucune authentification)
      # ======================================================================
      # Utilisez pour :
      # - Pages de status publiques
      # - API publiques
      # - Landing pages
      # - Endpoints Webhook
      # ⚠️ Attention : Ces services sont accessibles par TOUT LE MONDE

      # EXEMPLE : Page de status
      # {
      #   domain = ["status.hexaflare.net"];
      #   policy = "bypass";
      # }

      # EXEMPLE : API publique avec chemins spécifiques
      # {
      #   domain = ["api.hexaflare.net"];
      #   policy = "bypass";
      #   resources = ["^/api/v1/public.*$"]; # Seulement /api/v1/public/*
      # }

      # ======================================================================
      # 2. SERVICES CRITIQUES (two_factor - 2FA OBLIGATOIRE)
      # ======================================================================
      # Utilisez pour :
      # - Gestionnaires de mots de passe (Bitwarden, Vaultwarden)
      # - Panels d'administration
      # - Services financiers
      # - Stockage de documents sensibles
      # ✅ Recommandé : Toujours 2FA pour ces services

      # Bitwarden/Vaultwarden - 2FA pour TOUS les utilisateurs
      {
        domain = ["bitwarden.hexaflare.net"];
        policy = "two_factor";
        # subject omis = tous les utilisateurs authentifiés
      }

      # EXEMPLE : Panel admin (admins uniquement avec 2FA)
      # {
      #   domain = ["portainer.hexaflare.net" "proxmox.hexaflare.net"];
      #   policy = "two_factor";
      #   subject = ["group:admins"];
      # }

      # Nextcloud - 2FA pour admins, 1FA pour autres
      # Cette approche permet une sécurité graduée
      {
        domain = ["nextcloud.hexaflare.net"];
        policy = "two_factor";
        subject = ["group:admins"];
      }
      {
        domain = ["nextcloud.hexaflare.net"];
        policy = "one_factor";
        # Tous les autres utilisateurs authentifiés
      }

      # EXEMPLE : Service avec chemins admin protégés
      # {
      #   domain = ["grafana.hexaflare.net"];
      #   policy = "two_factor";
      #   resources = ["^/admin.*$"]; # Seulement /admin/*
      #   subject = ["group:admins"];
      # }

      # ======================================================================
      # 3. SERVICES STANDARDS (one_factor - Mot de passe uniquement)
      # ======================================================================
      # Utilisez pour :
      # - Services médias (Jellyfin, Plex)
      # - Photos (Immich)
      # - Demandes de médias (Jellyseerr, Overseerr)
      # - Services collaboratifs non-critiques
      # 💡 Bon équilibre sécurité/facilité pour un usage quotidien

      # Immich - Photos de famille
      {
        domain = ["immich.hexaflare.net"];
        policy = "one_factor";
        subject = ["group:family" "group:admins"];
      }

      # Jellyseerr - Demandes de médias
      {
        domain = ["jellyseerr.hexaflare.net"];
        policy = "one_factor";
        subject = ["group:family" "group:admins"];
      }

      # EXEMPLE : Services développement
      # {
      #   domain = ["gitea.hexaflare.net" "gitlab.hexaflare.net"];
      #   policy = "one_factor";
      #   subject = ["group:admins" "group:dev"];
      # }

      # EXEMPLE : Monitoring (lecture seule pour groupe monitoring)
      # {
      #   domain = ["grafana.hexaflare.net"];
      #   policy = "one_factor";
      #   subject = ["group:monitoring" "group:admins"];
      # }

      # ======================================================================
      # 4. RÈGLES AVANCÉES
      # ======================================================================

      # EXEMPLE : Protection par réseau (Tailscale)
      # {
      #   domain = ["internal.hexaflare.net"];
      #   policy = "bypass";
      #   networks = ["100.64.0.0/10"]; # Plage Tailscale
      # }
      # {
      #   domain = ["internal.hexaflare.net"];
      #   policy = "two_factor"; # Sinon 2FA requis
      # }

      # EXEMPLE : Protection par méthode HTTP
      # {
      #   domain = ["api.hexaflare.net"];
      #   policy = "bypass";
      #   resources = ["^/.*$"];
      #   methods = ["GET" "OPTIONS"]; # Seulement lecture
      # }
      # {
      #   domain = ["api.hexaflare.net"];
      #   policy = "two_factor";
      #   methods = ["POST" "PUT" "DELETE"]; # Écriture avec 2FA
      # }

      # EXEMPLE : Multi-domaines avec regex
      # {
      #   domain_regex = ["^.*\\.admin\\.hexaflare\\.net$"];
      #   policy = "two_factor";
      #   subject = ["group:admins"];
      # }

      # ======================================================================
      # 5. CATCH-ALL (optionnel si defaultPolicy = deny)
      # ======================================================================
      # Si vous utilisez defaultPolicy = "one_factor" ou "bypass",
      # ajoutez une règle catch-all pour plus de sécurité :
      # {
      #   domain = ["*.hexaflare.net"];
      #   policy = "deny";
      # }
    ];
  };

  # ==========================================================================
  # CONFIGURATION SYSTÈME
  # ==========================================================================

  my-services.infra.deployment-target.enable = true;

  networking.firewall = {
    allowedTCPPorts = [9091]; # Authelia
    allowedUDPPorts = [443 80]; # HTTP/HTTPS
  };
}

# ==============================================================================
# GUIDE RAPIDE - GROUPES D'UTILISATEURS
# ==============================================================================
#
# Définissez vos groupes dans /var/lib/authelia/users_database.yml :
#
# users:
#   admin:
#     displayname: "Administrator"
#     password: "$argon2id$..."
#     email: admin@hexaflare.net
#     groups:
#       - admins
#       - users
#
#   john:
#     displayname: "John Doe"
#     password: "$argon2id$..."
#     email: john@example.com
#     groups:
#       - dev
#       - users
#
#   marie:
#     displayname: "Marie"
#     password: "$argon2id$..."
#     email: marie@example.com
#     groups:
#       - family
#       - readonly
#
# GROUPES RECOMMANDÉS:
#   - admins      : Administrateurs (accès complet, 2FA recommandé)
#   - users       : Utilisateurs standards
#   - dev         : Développeurs (accès Gitea, Gitlab, etc.)
#   - family      : Famille (accès médias)
#   - monitoring  : Bots/services (lecture seule)
#   - readonly    : Lecture seule
#
# ==============================================================================
# COMMANDES UTILES
# ==============================================================================
#
# Créer un utilisateur :
#   just authelia-create-user
#
# Hasher un mot de passe :
#   just authelia-hash-password
#
# SSH sur le serveur :
#   just authelia-ssh
#   ssh nixos@authelia
#
# Voir les logs :
#   ssh nixos@authelia
#   journalctl -u authelia -f
#
# Redémarrer Authelia :
#   ssh nixos@authelia
#   sudo systemctl restart authelia
#
# Tester une règle d'accès :
#   ssh nixos@authelia
#   authelia access-control check-policy \
#     --url "https://immich.hexaflare.net" \
#     --username "john" \
#     --groups "family,users"
#
# Déployer les modifications :
#   git add hosts/authelia/default.nix
#   git commit -m "feat(authelia): update access control rules"
#   git push
#   ssh nixos@authelia 'cd ~/nixos-config && git pull && sudo nixos-rebuild switch --flake .#authelia'
#
# ==============================================================================
