{
  config,
  pkgs,
  ...
}: {
  dconf.settings = {
    "org/gnome/desktop/background" = {
      "picture-uri" = "file:///etc/nixos/wallpapers/gnome-wallpaper-adwaita.jpg";
      "picture-uri-dark" = "file:///etc/nixos/wallpapers/gnome-wallpaper-adwaita.jpg";
    };
  };
}
