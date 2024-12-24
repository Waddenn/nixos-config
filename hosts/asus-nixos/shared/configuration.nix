{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/templates/laptop.nix
  ];




}
