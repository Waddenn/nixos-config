{ config, pkgs, ... }:
{
  ############################################
  # Bluetooth / RTKit
  ############################################
  hardware.bluetooth.enable = true;
  security.rtkit.enable = true;
}
