{
  config,
  pkgs,
  ...
}: {
  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "brave-browser.desktop"
        "org.gnome.Console.desktop"
        "discord.desktop"
        "org.remmina.Remmina.desktop"
        "youtube-music.desktop"
      ];
    };
  };
}
