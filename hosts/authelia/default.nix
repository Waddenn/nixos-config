{...}: {
  profiles.lxc-base.enable = true;

  my-services.auth.authelia = {
    enable = true;
    domain = "hexaflare.net";
    port = 9091;

    # Utiliser SQLite par défaut (simple)
    database.type = "sqlite";

    # Redis local
    redis = {
      host = "localhost";
      port = 6379;
    };

    # Règles d'accès - Ordre d'évaluation important !
    # La première règle qui correspond est appliquée
    defaultPolicy = "deny"; # Sécurité par défaut : tout est bloqué sauf règles explicites

    accessControlRules = [
      # ============================================
      # Règles BYPASS (endpoints publics)
      # ============================================
      # {
      #   domain = ["status.hexaflare.net"];
      #   policy = "bypass";
      # }
      # {
      #   domain = ["api.hexaflare.net"];
      #   policy = "bypass";
      #   resources = ["^/api/public.*$"];
      # }

      # ============================================
      # Services CRITIQUES - 2FA OBLIGATOIRE
      # ============================================
      # Admin uniquement avec 2FA
      # {
      #   domain = ["grafana.hexaflare.net" "portainer.hexaflare.net"];
      #   policy = "two_factor";
      #   subject = ["group:admins"];
      # }

      # Tous les utilisateurs mais 2FA requis
      # {
      #   domain = ["bitwarden.hexaflare.net" "nextcloud.hexaflare.net"];
      #   policy = "two_factor";
      # }

      # ============================================
      # Services STANDARDS - 1FA
      # ============================================
      # Immich - Photos de famille
      {
        domain = ["immich.hexaflare.net"];
        policy = "one_factor";
        subject = ["group:family" "group:admins"];
      }

      # Jellyseerr - Médias
      {
        domain = ["jellyseerr.hexaflare.net"];
        policy = "one_factor";
        subject = ["group:family" "group:admins"];
      }

      # Gitea - Développement (admins + devs)
      # {
      #   domain = ["gitea.hexaflare.net"];
      #   policy = "one_factor";
      #   subject = ["group:admins" "group:dev"];
      # }

      # ============================================
      # EXEMPLE: Protection par ressources (chemins)
      # ============================================
      # Admin panel protégé, reste en bypass
      # {
      #   domain = ["app.hexaflare.net"];
      #   policy = "two_factor";
      #   resources = ["^/admin.*$"];
      #   subject = ["group:admins"];
      # }
      # {
      #   domain = ["app.hexaflare.net"];
      #   policy = "bypass";
      # }
    ];
  };

  my-services.infra.deployment-target.enable = true;

  networking.firewall = {
    allowedTCPPorts = [9091]; # Authelia
    allowedUDPPorts = [443 80];
  };
}
