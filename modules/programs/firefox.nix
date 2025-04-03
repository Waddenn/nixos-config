{ config, lib, pkgs, ... }:

{
  options = {
    firefox.enable = lib.mkEnableOption "Enable firefox";
  };

  config = lib.mkIf config.firefox.enable {
  programs.firefox = {
    enable = true;
  };
  };
}