{ config, lib, pkgs, ... }:

let
  cfg = config.linuxPackages;
in
{
  options = {
    linuxPackages = {
      enableLatest = lib.mkEnableOption "Enable linuxPackages_latest";
      enableZen = lib.mkEnableOption "Enable linuxPackages_zen";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enableLatest {
      boot.kernelPackages = pkgs.linuxPackages_latest;
    })

    (lib.mkIf cfg.enableZen {
      boot.kernelPackages = pkgs.linuxPackages_zen;
    })
  ];
}
