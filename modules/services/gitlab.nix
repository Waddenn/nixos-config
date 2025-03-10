{ config, lib, ... }:

{
  options.gitlab.enable = lib.mkEnableOption "Enable GitLab";

  config = lib.mkIf config.gitlab.enable {

    security.acme = {
      acceptTerms = true;  
      defaults.email = "tom@patelas.com"; 
    };

    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."git.hexaflare.net" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/keys/gitlab 0700 git git -"
      "f /var/keys/gitlab/db_password 0600 git git -"
      "f /var/keys/gitlab/root_password 0600 git git -"
      "f /var/keys/gitlab/db 0600 git git -"
      "f /var/keys/gitlab/secret 0600 git git -"
      "f /var/keys/gitlab/otp 0600 git git -"
      "f /var/keys/gitlab/jws 0600 git git -"
    ];

    systemd.services.generate-gitlab-secrets = {
      description = "Generate GitLab secret files if they are missing";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''
          for file in db_password root_password db secret otp jws; do
            if [ ! -s "/var/keys/gitlab/$file" ]; then
              openssl rand -base64 32 > "/var/keys/gitlab/$file"
              chown git:git "/var/keys/gitlab/$file"
              chmod 600 "/var/keys/gitlab/$file"
            fi
          done
        '';
      };
    };

    services.gitlab = {
      enable = true;
      databasePasswordFile = "/var/keys/gitlab/db_password";
      initialRootPasswordFile = "/var/keys/gitlab/root_password";
      https = true;
      host = "git.hexaflare.net";
      port = 443;
      user = "git";
      group = "git";
      databaseUsername = "git";  
      smtp = {
        enable = true;
        address = "localhost";
        port = 25;
      };
      secrets = {
        dbFile = "/var/keys/gitlab/db";
        secretFile = "/var/keys/gitlab/secret";
        otpFile = "/var/keys/gitlab/otp";
        jwsFile = "/var/keys/gitlab/jws";
      };

      extraConfig = {
        gitlab = {
          email_from = "gitlab-no-reply@example.com";
          email_display_name = "Example GitLab";
          email_reply_to = "gitlab-no-reply@example.com";
          default_projects_features = { builds = false; };
        };
      };
    };

  };
}
