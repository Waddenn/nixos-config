{ config, pkgs, ... }:

{
  imports = [
    ../../modules/common/gaming.nix
    ../../home-manager/programs/default.nix
    ../../gnome/extensions.nix
    ../../gnome/keyboard-shortcuts.nix
    ../../gnome/interface.nix
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