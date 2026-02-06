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

    # Règles d'accès par défaut
    accessControlRules = [
      # Immich - Photos de famille (authentification simple)
      {
        domain = ["immich.hexaflare.net"];
        policy = "one_factor";
        subject = ["group:family" "group:admins"];
      }

      # Exemple: protéger Gitea avec authentification à 1 facteur
      # {
      #   domain = ["gitea.hexaflare.net"];
      #   policy = "one_factor";
      # }

      # Exemple: protéger des services sensibles avec 2FA
      # {
      #   domain = ["nextcloud.hexaflare.net" "bitwarden.hexaflare.net"];
      #   policy = "two_factor";
      # }

      # Exemple: bypass pour certains endpoints publics
      # {
      #   domain = ["*.hexaflare.net"];
      #   policy = "bypass";
      #   resources = ["^/api/public.*$"];
      # }
    ];
  };

  my-services.infra.deployment-target.enable = true;

  networking.firewall = {
    allowedTCPPorts = [9091]; # Authelia
    allowedUDPPorts = [443 80];
  };
}
