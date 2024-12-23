{ config, pkgs, ... }:

{
  imports = [
    ../shared/programs/default.nix
    ../shared/desktop/gnome/extensions.nix
    ../shared/desktop/gnome/keyboard-shortcuts.nix
    ../shared/desktop/gnome/interface.nix
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