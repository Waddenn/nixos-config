{
  config,
  lib,
  pkgs,
  ...
}: {
  options.onlyoffice.enable = lib.mkEnableOption "Enable onlyoffice";

  config = lib.mkIf config.onlyoffice.enable {
    services.onlyoffice = {
      enable = true;
      securityNonceFile = "${pkgs.writeText "onlyoffice-nonce" "set $secure_link_secret \"placeholder-secret-change-me\";"}";
    };
    networking.firewall.allowedTCPPorts = [8000];
  };
}
