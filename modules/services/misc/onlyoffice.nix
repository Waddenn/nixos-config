{
  config,
  lib,
  pkgs,
  ...
}: {
  options.my-services.misc.onlyoffice.enable = lib.mkEnableOption "Enable onlyoffice";

  config = lib.mkIf config.my-services.misc.onlyoffice.enable {
    services.onlyoffice = {
      enable = true;
      securityNonceFile = "${pkgs.writeText "onlyoffice-nonce" "set $secure_link_secret \"placeholder-secret-change-me\";"}";
    };
    networking.firewall.allowedTCPPorts = [8000];
  };
}
