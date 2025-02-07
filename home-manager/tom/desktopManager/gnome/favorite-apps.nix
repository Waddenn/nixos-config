{ config, pkgs, ... }:

{

  dconf.settings = {

    "org/gnome/shell" = {
      favorite-apps = [
        "firefox.desktop"
        "org.gnome.Console.desktop"
        "dev.vencord.Vesktop.desktop"
        "org.remmina.Remmina.desktop"
        "youtube-music.desktop"
      ];

    };

  };

}
