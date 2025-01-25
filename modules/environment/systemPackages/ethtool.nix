{ config, lib, pkgs, ... }:

{
  options.ethtool.enable = lib.mkEnableOption "Enable ethtool";

  config = lib.mkIf config.ethtool.enable {

  environment.systemPackages = [
    pkgs.ethtool
  ];

  };
}
