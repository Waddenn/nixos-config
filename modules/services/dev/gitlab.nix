# sudo mkdir -p /var/keys/gitlab
# sudo chmod 700 /var/keys/gitlab
# sudo chown git:git /var/keys/gitlab
# for file in db_password root_password db secret otp jws; do
#     if [ ! -s "/var/keys/gitlab/$file" ]; then
#         echo "Generating secret for $file..."
#         openssl rand -base64 32 | sudo tee "/var/keys/gitlab/$file" > /dev/null
#         sudo chown git:git "/var/keys/gitlab/$file"
#         sudo chmod 600 "/var/keys/gitlab/$file"
#     else
#         echo "File /var/keys/gitlab/$file already exists, skipping..."
#     fi
# done
{
  config,
  lib,
  ...
}: {
  options.gitlab.enable = lib.mkEnableOption "Enable gitlab";

  config = lib.mkIf config.gitlab.enable {
    security.acme = {
      acceptTerms = true;
      defaults.email = "tom@patelas.com";
    };

    services.nginx = {
      enable = false;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."git.hexaflare.net" = {
        enableACME = false;
        forceSSL = false;
        locations."/".proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
      };
    };

    services.gitlab = {
      enable = true;
      databasePasswordFile = "/var/keys/gitlab/db_password";
      initialRootPasswordFile = "/var/keys/gitlab/root_password";
      https = false;
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
        activeRecordPrimaryKeyFile = "/var/keys/gitlab/ar_primary_key";
        activeRecordDeterministicKeyFile = "/var/keys/gitlab/ar_deterministic_key";
        activeRecordSaltFile = "/var/keys/gitlab/ar_salt";
      };

      extraConfig = {
        gitlab = {
          email_from = "gitlab-no-reply@example.com";
          email_display_name = "Example GitLab";
          email_reply_to = "gitlab-no-reply@example.com";
          default_projects_features = {builds = false;};
        };
      };
    };

    networking.firewall.allowedTCPPorts = [443 80];
  };
}
