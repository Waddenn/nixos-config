{ config, pkgs, ... }:

{

  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      remember-mount-password = true;
      enabled-extensions = [
        "hidetopbar@mathieu.bidon.ca"
        "tailscale@joaophi.github.com"
        "AlphabeticalAppGrid@stuarthayhurst"
        "appindicatorsupport@rgcjonas.gmail.com"
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
        "Battery-Health-Charging@maniacx.github.com"
        "search-light@icedman.github.com"
        "blur-my-shell@aunetx"
      ]; 
    };

    "org/gnome/shell/extensions/system-monitor" = {
      show-cpu = true;
      show-download = false;
      show-memory = true;
      show-swap = true;
      show-upload = false;
    };

    "org/gnome/shell/extensions/Battery-Health-Charging" = {
      amend-power-indicator = true;
      charging-mode = "max";
      show-battery-panel2 = false;
      show-preferences = false;
      show-system-indicator = false;
    };
  };

}
