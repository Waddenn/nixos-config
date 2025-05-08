{
  config,
  pkgs,
  ...
}: {
  dconf.settings = {
    "org/gnome/desktop/background" = {
      "picture-uri" = "file:///etc/nixos/home-manager/tom/wallpapers/gnome-wallpaper-adwaita.jpg";
      "picture-uri-dark" = "file:///etc/nixos/home-manager/tom/wallpapers/gnome-wallpaper-adwaita.jpg";
    };
  };
}
