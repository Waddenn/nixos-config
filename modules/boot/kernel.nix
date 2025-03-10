{ config, lib, pkgs, ... }:

{
  options.linuxPackages_latest.enable = lib.mkEnableOption "linuxPackages_latest";

  config = lib.mkIf config.linuxPackages_latest.enable {
    boot.kernelPackages = pkgs.linuxPackages_latest;

  };
}
