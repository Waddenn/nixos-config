{ config, pkgs, ... }:

{

  dconf.settings = {

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      clock-show-weekday = true;
      accent-color = "slate";
    };

    "org.gnome.system.locale" = {
      custom-value = "fr_FR.UTF-8";
    };


  };

}
