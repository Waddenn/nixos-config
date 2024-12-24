{ config, pkgs, ... }:

{

  system.autoUpgrade = {
    enable = true;
    dates = "daily";
    persistent = true;
    flags = [ "--update-input" "nixpkgs" ];
  };

}
