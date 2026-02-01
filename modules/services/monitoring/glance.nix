{
  config,
  lib,
  ...
}: let
  # stylix dependency removed as it's not present in this flake
  rgb-to-hsl = color: "200 50 50";
in {
  options.my-services.monitoring.glance.enable = lib.mkEnableOption "Enable the Glance dashboard";

  config = lib.mkIf config.my-services.monitoring.glance.enable {
    services.glance = {
      enable = true;
      settings = {
        theme = {
          contrast-multiplier = lib.mkForce 1.4;
        };
        pages = [
          {
            hide-desktop-navigation = true;
            columns = [
              {
                size = "small";
                widgets = [
                  {
                    type = "clock";
                    hour-format = "24h";
                  }
                  {
                    type = "weather";
                    location = "Paris, France";
                  }
                  {
                    type = "markets";
                    markets = [
                      {
                        symbol = "BTC-USD";
                        name = "Bitcoin";
                        chart-link = "https://www.tradingview.com/chart/?symbol=INDEX:BTCUSD";
                      }
                      {
                        symbol = "ETH-USD";
                        name = "Ethereum";
                        chart-link = "https://www.tradingview.com/chart/?symbol=INDEX:ETHUSD";
                      }
                    ];
                  }
                ];
              }
              {
                size = "full";
                widgets = [
                  {
                    type = "search";
                    search-engine = "duckduckgo";
                  }
                  {
                    type = "bookmarks";
                    groups = [
                      {
                        title = "Services";
                        same-tab = true;
                        color = "200 50 50";
                        links = [
                          {
                            title = "Nextcloud";
                            url = "https://nextcloud.hexaflare.net";
                          }
                          {
                            title = "Gitea";
                            url = "https://gitea.hexaflare.net";
                          }
                          {
                            title = "Linkwarden";
                            url = "https://linkwarden.hexaflare.net";
                          }
                          {
                            title = "Bitwarden";
                            url = "https://bitwarden.hexaflare.net";
                          }
                        ];
                      }
                      {
                        title = "Infrastructure";
                        same-tab = true;
                        color = "100 50 50";
                        links = [
                          {
                            title = "Authentik";
                            url = "https://auth.hexaflare.net";
                          }
                          {
                            title = "Caddy";
                            url = "https://caddy.hexaflare.net"; # Placeholder
                          }
                          {
                            title = "Proxmox";
                            url = "https://nuc-pve-1:8006";
                          }
                        ];
                      }
                      {
                        title = "Media";
                        same-tab = true;
                        color = "50 50 50";
                        links = [
                          {
                            title = "Immich";
                            url = "https://immich.hexaflare.net";
                          }
                          {
                            title = "Jellyseerr";
                            url = "https://jellyseerr.hexaflare.net";
                          }
                        ];
                      }
                    ];
                  }
                  {
                    type = "group";
                    widgets = [
                      {
                        type = "monitor";
                        title = "Status";
                        cache = "1m";
                        sites = [
                          {
                            title = "Nextcloud";
                            url = "https://nextcloud.hexaflare.net";
                            icon = "si:nextcloud";
                          }
                          {
                            title = "Gitea";
                            url = "https://gitea.hexaflare.net";
                            icon = "si:gitea";
                          }
                          {
                            title = "Authentik";
                            url = "https://auth.hexaflare.net";
                            icon = "si:authentik";
                          }
                          {
                            title = "Immich";
                            url = "https://immich.hexaflare.net";
                            icon = "si:immich";
                          }
                        ];
                      }
                    ];
                  }
                  {
                    type = "server-stats";
                    servers = [
                      {
                        type = "local";
                        name = "Glance Node";
                      }
                    ];
                  }
                ];
              }
            ];
            name = "Home";
          }
        ];
        server = {
          port = 5678;
          host = "0.0.0.0";
        };
        openFirewall = false; # Handled by Caddy
      };
    };
    users.users.glance = {
      isSystemUser = true;
      description = "User for Glance service";
      group = "glance";
      home = "/var/lib/glance";
    };
    networking.firewall.allowedTCPPorts = [5678];

    users.groups.glance = {};
  };
}
