{ config, lib, pkgs, ... }:

{
  options.caddy.enable = lib.mkEnableOption "Enable caddy";

  config = lib.mkIf config.caddy.enable {

  services.caddy = {
    enable = true;  
    logDir = "/var/log/caddy";  
    dataDir = "/var/lib/caddy"; 
    extraConfig = ''
      {
        debug
      }
      
      hexaflare.net {
        reverse_proxy 192.168.1.110:8081
        tls {
          dns cloudflare {env.CF_API_TOKEN}  
        }
      }
    '';
  };

  # environment.variables = {
  #   CF_API_TOKEN = "ton_api_token";  
  # };

  systemd.services.caddy = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  services.caddy.package = pkgs.caddy.overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [ pkgs.go ];
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.xcaddy ];
    postInstall = (old.postInstall or "") + ''
      export GOPROXY=https://proxy.golang.org,direct
      export GOSUMDB=off
      export GOFLAGS="-mod=mod"  
      xcaddy build --with github.com/caddy-dns/cloudflare
    '';
  });



  };
}
