{ config, lib, pkgs, ... }:

{
  options = {
    python314.enable = lib.mkEnableOption "Enable python314";
  };

  config = lib.mkIf config.python314.enable {
  environment.systemPackages = with pkgs; [
    python314
  ]; 
  };
}