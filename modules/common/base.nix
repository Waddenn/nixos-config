{ config, pkgs, ... }:

{

  ###############################
  # Options Nix
  ###############################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  security.rtkit.enable = true;
  hardware.bluetooth.enable = true;

}
