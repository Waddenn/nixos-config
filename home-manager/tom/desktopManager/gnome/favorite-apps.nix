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
        "code.desktop"
        "discord.desktop"
        "youtube-music.desktop"
      ];
    };
  };
}
