{ config, pkgs, ... }:

{
  imports = [
    ../../home-manager/programs/default.nix
  ];

  home.username = "tom";
  home.homeDirectory = "/home/tom";

  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

}