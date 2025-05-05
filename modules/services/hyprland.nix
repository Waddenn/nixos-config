{
  config,
  lib,
  pkgs,
  ...
}: {
  options.hyprland.enable = lib.mkEnableOption "Enable Hyprland integration system-wide";

  config = lib.mkIf config.hyprland.enable {
    programs.hyprland = {
      enable = true;
    };
  };
}
