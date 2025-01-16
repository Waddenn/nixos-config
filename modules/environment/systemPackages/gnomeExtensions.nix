{ config, lib, pkgs, ... }:

{
  options.gnomeExtensions.enable = lib.mkEnableOption "Enable gnomeExtensions";

  config = lib.mkIf config.gnomeExtensions.enable {

  environment.systemPackages = with pkgs.gnomeExtensions; [
    hide-top-bar
    tailscale-qs
    appindicator
    alphabetical-app-grid
    search-light
    battery-health-charging
    system-monitor
    bluetooth-battery-meter
    blur-my-shell
  ];

  };
}
