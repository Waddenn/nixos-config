{ config, lib, pkgs, ... }:

{
  options.cloudflared.enable = lib.mkEnableOption "Enable cloudflared";

  config = lib.mkIf config.cloudflared.enable {
    {
  services.cloudflared = {
    enable = true;
    tunnels = {
      "00000000-0000-0000-0000-000000000000" = {
        credentialsFile = "${config.sops.secrets.cloudflared-creds.path}";
        default = "http_status:404";
      };
    };
  };
}
  };
}
