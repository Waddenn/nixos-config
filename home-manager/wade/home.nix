{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./wofi
    ./hyprpaper
    ./animation.nix
    ./themes/nixy.nix
  ];
  home.username = "wade";
  home.homeDirectory = "/home/wade";
  home.packages = with pkgs; [
    obsidian
    blanket
    papers
    whatip
    vscode
    youtube-music
    fastfetch
    discord
    git
  ];

  programs.kitty = {
    enable = true;
    extraConfig = ''
      confirm_os_window_close 0
    '';
  };

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
        "$mainMod,       T, togglefloating,"
        "$mainMod,F, fullscreen,"
        "$mainMod,        d, exec, wofi --show drun"
        ", XF86AudioRaiseVolume, exec, pamixer -i 5"
        ", XF86AudioLowerVolume, exec, pamixer -d 5"
        ", XF86MonBrightnessUp, exec, brightnessctl s +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl s 5%-"
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
      ];

      input = {
        kb_layout = "fr";
        natural_scroll = false;
      };

      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 3;
      };

      # monitor = [
      #   "SDC4172,2880x1800@60,0x0,1"
      # ];
    };
  };

  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
}
