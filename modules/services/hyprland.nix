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
      # set the flake package
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      withUWSM = true;
      # make sure to also set the portal package, so that they are in sync
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };
  };
}
