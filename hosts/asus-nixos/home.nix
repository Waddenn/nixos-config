{
  config,
  pkgs,
  lib,
  ...
}: let
  border-size = config.theme.border-size;
  gaps-in = config.theme.gaps-in;
  gaps-out = config.theme.gaps-out;
  active-opacity = config.theme.active-opacity;
  inactive-opacity = config.theme.inactive-opacity;
  rounding = config.theme.rounding;
  blur = config.theme.blur;
  keyboardLayout = config.var.keyboardLayout;
  background = "rgb(" + config.lib.stylix.colors.base00 + ")";
in {
  imports = [
    ../../home/system/wofi
    ../../home/system/hyprpaper
    ../../home/system/clipman
    ../../home/system/hyprpanel
    # ../../home/system/hyprland/hyprspace.nix
    ../../home/system/hyprlock
    ../../home/system/zathura
    ../../home/script
    ../../home/system/hyprland
    ../../home/system/udiskie
    ../../home/system/hypridle
    ../../home/system/mime
    ../../home/programs/thunar
    ../../home/programs/zen
    ../../home/programs/fish
    ../../home/programs/git
    ../../themes/nixy.nix
    ../../modules/programs/fzf.nix
    ./variables.nix
  ];
  home.username = "tom";
  home.homeDirectory = "/home/tom";

  home.file.".face.icon" = {
    source = ./profile_picture.png;
  };

  programs.home-manager.enable = true;

  home.stateVersion = "25.05";

  programs.kitty = {
    enable = true;
    extraConfig = ''
      confirm_os_window_close 0
    '';
  };
}
