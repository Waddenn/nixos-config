{ config, pkgs, ... }:

{
  
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany
    geary
    evince
    totem
    gnome-connections
    gnome-music
    gnome-music
    gnome-shell-extensions
  ];

}
