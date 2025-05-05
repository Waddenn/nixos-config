{
  config,
  lib,
  pkgs,
  ...
}: {
  options.hyprland.enable = lib.mkEnableOption "Enable hyprland";

  config = lib.mkIf config.hyprland.enable {
    programs.hyprland.enable = true;

    environment.systemPackages = with pkgs; [
      hyprland
      waybar
      wofi
      alacritty
      kitty
      wl-clipboard
      xdg-utils
      xdg-desktop-portal
      xdg-desktop-portal-hyprland
      (pkgs.writeShellScriptBin "start-hyprland" ''
        exec Hyprland
      '')
    ];

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-hyprland];
    };
  };
}
