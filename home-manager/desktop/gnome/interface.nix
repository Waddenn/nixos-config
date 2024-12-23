{ config, pkgs, ... }:

{

  dconf.settings = {

    "org/gnome/desktop/background" = {
        "picture-uri" = "../../../wallpapers/makima.png";
    };

    "org/gnome/shell" = {
      favorite-apps = [
        "firefox.desktop"
        "org.gnome.Console.desktop"
        "vesktop.desktop"
        "org.remmina.Remmina.desktop"
        "youtube-music.desktop"
      ];

    };

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
