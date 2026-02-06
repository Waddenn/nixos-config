{
  config,
  lib,
  ...
}: {
  options = {
    immich.enable = lib.mkEnableOption "Enable immich";
  };

  config = lib.mkIf config.immich.enable {
    # Immich is only accessible via the Caddy reverse proxy on the internal network
    # This ensures all public traffic goes through HTTPS with security headers
    # Caddy connects via internal IP (192.168.40.115:2283)
    services.immich.enable = true;
    services.immich.port = 2283;
    services.immich.host = "0.0.0.0"; # Listen on internal network for Caddy reverse proxy
    services.immich.settings = {
      server.externalDomain = "https://immich.hexaflare.net";

      # OIDC with Authelia for web and mobile clients.
      oauth = {
        enabled = true;
        issuerUrl = "https://auth.hexaflare.net/.well-known/openid-configuration";
        clientId = "immich";
        clientSecret._secret = config.sops.secrets.immich_oauth_client_secret.path;
        scope = "openid email profile";
        tokenEndpointAuthMethod = "client_secret_post";
        buttonText = "Se connecter avec Authelia";
      };

      # Force SSO via Authelia only (hide local email/password login).
      passwordLogin.enabled = false;
    };

    sops.secrets.immich_oauth_client_secret = {
      sopsFile = ../../../secrets/secrets.yaml;
      owner = "immich";
      group = "immich";
      restartUnits = ["immich-server.service"];
    };
    # Note: Firewall configured in host to allow only internal network access
  };
}
