{ config, lib, pkgs, ... }:

{
  options = {
    python313.enable = lib.mkEnableOption "Enable python313";
  };

  config = lib.mkIf config.python313.enable {
  environment.systemPackages = with pkgs; [
    python313
  ]; 
  };
}