{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  options.hyprland.enable = lib.mkEnableOption "Enable Hyprland integration system-wide";

  config = lib.mkIf config.hyprland.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      package = inputs.hyprland.packages."${pkgs.system}".hyprland;
      portalPackage =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };
  };
}
