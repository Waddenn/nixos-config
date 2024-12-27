{ config, pkgs, ... }:

{
  imports = [
    ./packages/default.nix
    ./desktopManager/gnome/dconf-settings/background.nix
    ./desktopManager/gnome/dconf-settings/extensions.nix
    ./desktopManager/gnome/dconf-settings/favorite-apps.nix
    ./desktopManager/gnome/dconf-settings/interface.nix
    ./desktopManager/gnome/dconf-settings/keybindings.nix
  ];

  home.username = "tom";
  home.homeDirectory = "/home/tom";

  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

    programs.git = {
    enable = true;
    userName  = "waddenn";
    userEmail = "waddenn.github@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

}