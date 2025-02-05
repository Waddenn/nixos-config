{ config, lib, pkgs, ... }:

{
  options.beszel.enable = lib.mkEnableOption "Enable beszel";

  config = lib.mkIf config.beszel.enable {

  environment.systemPackages = with pkgs; [
    beszel
  ];

  };
}
