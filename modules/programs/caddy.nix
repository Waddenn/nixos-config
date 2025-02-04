{ config, lib, pkgs, ... }:

{
  options.caddy.enable = lib.mkEnableOption "Enable caddy";

  config = lib.mkIf config.caddy.enable {

  environment.systemPackages = with pkgs; [
    caddy
  ];

  };
}
