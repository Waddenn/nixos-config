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
      enable6_6 = lib.mkEnableOption "Enable linuxPackages_6_6";
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

    (lib.mkIf cfg.enable6_6 {
      boot.kernelPackages = pkgs.linuxPackages_6_6;
    })
  ];
}