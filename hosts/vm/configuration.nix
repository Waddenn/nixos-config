{ config, lib, pkgs, inputs, username, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "vm";

  services.fwupd.enable = true;

  programs.direnv.enable = true;

  system.stateVersion = "25.05";

  hardware.bluetooth.enable = true;
  security.rtkit.enable = true;

}
