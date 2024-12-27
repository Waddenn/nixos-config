{ config, pkgs, ... }:

{

  dconf.settings = {

    "org/gnome/desktop/background" = {
        "picture-uri" = "file:///etc/nixos/wallpapers/gnome-wallpaper-adwaita.jpg";
        "picture-uri-dark" = "file:///etc/nixos/wallpapers/gnome-wallpaper-adwaita.jpg";
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
