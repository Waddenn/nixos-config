{
  config,
  pkgs,
  ...
}: {
  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "firefox.desktop"
        "org.gnome.Console.desktop"
        "discord.desktop"
        "org.remmina.Remmina.desktop"
        "youtube-music.desktop"
      ];
    };
  };
}
