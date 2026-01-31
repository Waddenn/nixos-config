{
  config,
  lib,
  ...
}: let
  # stylix dependency removed as it's not present in this flake
  rgb-to-hsl = color: "200 50 50"; 
in {
  options.glance.enable = lib.mkEnableOption "Enable the Glance dashboard";

  config = lib.mkIf config.glance.enable {
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
                        symbol = "SOL-USD";
                        name = "Solana";
                        chart-link = "https://www.tradingview.com/chart/?symbol=INDEX:SOLUSD";
                      }
                      {
                        symbol = "ETH-USD";
                        name = "Ethereum";
                        chart-link = "https://www.tradingview.com/chart/?symbol=INDEX:ETHUSD";
                      }
                    ];
                  }
                  {
                    type = "dns-stats";
                    service = "adguard";
                    url = "https://adguard.hadi.diy";
                    username = "hadi";
                    password = "${secret:adguard-pwd}";
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
                        title = "";
                        same-tab = true;
                        color = "200 50 50";
                        links = [
                          {
                            title = "ProtonMail";
                            url = "https://proton.me/mail";
                          }
                          {
                            title = "Github";
                            url = "https://github.com";
                          }
                          {
                            title = "Youtube";
                            url = "https://youtube.com";
                          }
                          {
                            title = "Figma";
                            url = "https://figma.com";
                          }
                        ];
                      }
                      {
                        title = "Docs";
                        same-tab = true;
                        color = "200 50 50";
                        links = [
                          {
                            title = "Nixpkgs repo";
                            url = "https://github.com/NixOS/nixpkgs";
                          }
                          {
                            title = "Nixvim";
                            url = "https://nix-community.github.io/nixvim/";
                          }
                          {
                            title = "Hyprland wiki";
                            url = "https://wiki.hyprland.org/";
                          }
                          {
                            title = "Search NixOS";
                            url = "https://search-nixos.hadi.diy";
                          }
                        ];
                      }
                      {
                        title = "Homelab";
                        same-tab = true;
                        color = "100 50 50";
                        links = [
                          {
                            title = "Router";
                            url = "http://192.168.1.254/";
                          }
                          {
                            title = "Cloudflare";
                            url = "https://dash.cloudflare.com/";
                          }
                        ];
                      }
                      {
                        title = "Work";
                        same-tab = true;
                        color = "50 50 50";
                        links = [
                          {
                            title = "Outlook";
                            url = "https://outlook.office.com/";
                          }
                          {
                            title = "Teams";
                            url = "https://teams.microsoft.com/";
                          }
                          {
                            title = "Office";
                            url = "https://www.office.com/";
                          }
                        ];
                      }
                      {
                        title = "Cyber";
                        same-tab = true;
                        color = rgb-to-hsl "base09";
                        links = [
                          {
                            title = "CyberChef";
                            url = "https://cyberchef.org/";
                          }
                          {
                            title = "TryHackMe";
                            url = "https://tryhackme.com/";
                          }
                          {
                            title = "RootMe";
                            url = "https://www.root-me.org/";
                          }
                          {
                            title = "Exploit-DB";
                            url = "https://www.exploit-db.com/";
                          }
                          {
                            title = "CrackStation";
                            url = "https://crackstation.net/";
                          }
                        ];
                      }
                      {
                        title = "Misc";
                        same-tab = true;
                        color = rgb-to-hsl "base01";
                        links = [
                          {
                            title = "Svgl";
                            url = "https://svgl.app/";
                          }
                          {
                            title = "Excalidraw";
                            url = "https://excalidraw.com/";
                          }
                          {
                            title = "Cobalt (Downloader)";
                            url = "https://cobalt.tools/";
                          }
                          {
                            title = "Mazanoke (Image optimizer)";
                            url = "https://mazanoke.com/";
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
                        name = "Jack";
                      }
                    ];
                  }
                  {
                    type = "group";
                    widgets = [
                      {
                        type = "monitor";
                        title = "Services";
                        cache = "1m";
                        sites = [
                          {
                            title = "Vaultwarden";
                            url = "https://vault.hadi.diy";
                            icon = "si:bitwarden";
                          }
                          {
                            title = "Nextcloud";
                            url = "https://cloud.hadi.diy";
                            icon = "si:nextcloud";
                          }
                          {
                            title = "Adguard";
                            url = "https://adguard.hadi.diy";
                            icon = "si:adguard";
                          }
                          {
                            title = "Hoarder";
                            url = "https://hoarder.hadi.diy";
                            icon = "si:bookstack";
                          }
                          {
                            title = "Mealie";
                            url = "https://mealie.hadi.diy";
                            icon = "si:mealie";
                          }
                        ];
                      }
                      {
                        type = "monitor";
                        title = "*arr";
                        cache = "1m";
                        sites = [
                          {
                            title = "Jellyfin";
                            url = "https://jellyfin.hexaflare.net";
                            icon = "si:jellyfin";
                          }
                          {
                            title = "Jellyseerr";
                            url = "https://jellyseerr.hexaflare.net";
                            icon = "si:odysee";
                          }
                          {
                            title = "Radarr";
                            url = "https://radarr.hadi.diy";
                            icon = "si:radarr";
                          }
                          {
                            title = "Sonarr";
                            url = "https://sonarr.hadi.diy";
                            icon = "si:sonarr";
                          }
                          {
                            title = "Prowlarr";
                            url = "https://prowlarr.hadi.diy";
                            icon = "si:podcastindex";
                          }
                          {
                            title = "SABnzbd";
                            url = "https://sabnzbd.hadi.diy";
                            icon = "si:sabanci";
                          }
                          {
                            title = "Transmission";
                            url = "https://transmission.hadi.diy";
                            icon = "si:transmission";
                          }
                        ];
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
        openFirewall = true;
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
