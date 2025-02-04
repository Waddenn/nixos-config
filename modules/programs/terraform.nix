{ config, lib, pkgs, ... }:

{
  options.direnv.enable = lib.mkEnableOption "Enable terraform";

  config = lib.mkIf config.direnv.enable {

  environment.systemPackages = with pkgs; [
    terraform
  ];

  };
}
