{ config, pkgs, ... }:
{
  
  services.xserver = {
    enable = true;

    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    xkb = {
      layout = "fr";
      variant = "";
    };
  };

  environment.systemPackages = with pkgs.gnomeExtensions; [
    hide-top-bar
    tailscale-qs
    appindicator
    alphabetical-app-grid
    search-light
    battery-health-charging
    system-monitor
    bluetooth-battery-meter
    blur-my-shell
  ];

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany
    geary
    evince
    totem
    gnome-connections
    gnome-music
    gnome-music
    gnome-shell-extensions
  ];

}
