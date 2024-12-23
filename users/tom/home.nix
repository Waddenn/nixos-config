{ config, pkgs, ... }:

{
  imports = [
    ../../home-manager/programs/default.nix
    ../../home-manager/gnome/extensions.nix
    ../../home-manager/gnome/keyboard-shortcuts.nix
    ../../home-manager/gnome/interface.nix
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
  
  programs.firefox = {
    enable = true;                    
  };

}