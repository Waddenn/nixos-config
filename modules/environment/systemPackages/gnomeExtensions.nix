{ config, pkgs, ... }:

{
  
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


}
