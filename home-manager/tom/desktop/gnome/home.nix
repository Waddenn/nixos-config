{ config, pkgs, ... }:

{
  imports = [
    ../../programs/default.nix
    ./extensions.nix
    ./keyboard-shortcuts.nix
    ./interface.nix
  ];

  home.username = "tom";
  home.homeDirectory = "/home/tom";

  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

}