{ config, lib, pkgs, ... }:

let
  cfg = config.linuxPackages;
in
{
  options = {
    linuxPackages = {
      enableLatest = lib.mkEnableOption "Enable linuxPackages_latest";
      enableZen = lib.mkEnableOption "Enable linuxPackages_zen";
      enableTesting = lib.mkEnableOption "Enable linuxPackages_testing";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enableLatest {
      boot.kernelPackages = pkgs.linuxPackages_latest;
    })

    (lib.mkIf cfg.enableZen {
      boot.kernelPackages = pkgs.linuxPackages_zen;
    })

    (lib.mkIf cfg.enableTesting {
      boot.kernelPackages = pkgs.linuxPackages_testing;
    })
  ];
}
