{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./wofi
    ./hyprpanel
    ./themes/nixy.nix
  ];
  home.username = "wade";
  home.homeDirectory = "/home/wade";
  home.packages = with pkgs; [
    kitty
    firefox
    wofi
  ];
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    settings = {
      "$mainMod" = "SUPER";
      bind = [
        "$mainMod,        Return, exec, kitty"
        "$mainMod,        q, killactive,"
        "$mainMod SHIFT,  q, exit,"
        "$mainMod,        e, exec, nautilus"
        "$mainMod,       F, togglefloating,"
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"
        "$mainMod,        d, exec, wofi --show drun"
      ];
      input = {
        kb_layout = "fr";
      };
    };
  };

  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
}
