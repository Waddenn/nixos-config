{ config, lib, pkgs, ... }:

{
  options.gnome-excludePackages.enable = lib.mkEnableOption "Enable gnome-excludePackages";

  config = lib.mkIf config.gnome-excludePackages.enable {

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
    gnome-software
  ];

  };
}
