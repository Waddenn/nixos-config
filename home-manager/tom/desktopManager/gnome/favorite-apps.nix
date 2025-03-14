{ config, pkgs, ... }:

{

  dconf.settings = {

    "org/gnome/shell" = {
      favorite-apps = [
        "app.zen_browser.zen.desktop"
        "org.gnome.Console.desktop"
        "dev.vencord.Vesktop.desktop"
        "org.remmina.Remmina.desktop"
        "youtube-music.desktop"
      ];

    };

  };

}
