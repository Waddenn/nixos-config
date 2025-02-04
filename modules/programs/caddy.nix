{ config, lib, pkgs, ... }:

{
  options.direnv.enable = lib.mkEnableOption "Enable caddy";

  config = lib.mkIf config.direnv.enable {

  environment.systemPackages = with pkgs; [
    caddy
  ];

  };
}
