{pkgs, ...}: {
  wayland.windowManager.hyprland = {
    settings = {
      "$mainMod" = "SUPER";
      bind = [
        "$mainMod,RETURN, exec, uwsm app -- ${pkgs.kitty}/bin/kitty"
        "$mainMod,K, exec,  uwsm app -- ${pkgs.bitwarden}/bin/bitwarden"
        "$mainMod,L, exec,  uwsm app -- ${pkgs.hyprlock}/bin/hyprlock"
        "$mainMod SHIFT,  q, exit,"
        "$mainMod,        q, killactive,"
        "$mainMod SHIFT,  e, exec, ${pkgs.wofi-emoji}/bin/wofi-emoji"
        "$mainMod,E, exec, uwsm app -- ${pkgs.kitty}/bin/kitty -e yazi"
        "$mainMod,B, exec,  uwsm app -- firefox"
        "$mainMod,       right, movefocus, r"
        "$mainMod,       up, movefocus, u"
        "$mainMod,       down, movefocus, d"
        "$mainMod,       T, togglefloating,"
        "$mainMod,F, fullscreen,"
        "$mainMod,        X, exec, powermenu"
        "$mainMod,        space, exec, menu"
        "$mainMod,        C, exec, quickmenu"
        "$mainMod SHIFT,  SPACE, exec, hyprfocus-toggle"
        # "$mainMod,P, exec,  uwsm app -- ${pkgs.planify}/bin/io.github.alainm23.planify"
        "$mainMod, code:10, workspace, 1"
        "$mainMod, code:11, workspace, 2"
        "$mainMod, code:12, workspace, 3"
        "$mainMod, code:13, workspace, 4"
        "$mainMod, code:14, workspace, 5"
        "$mainMod, code:15, workspace, 6"
        "$mainMod, code:16, workspace, 7"
        "$mainMod, code:17, workspace, 8"
        "$mainMod, code:18, workspace, 9"
        "$mainMod, code:19, workspace, 10"
        "$mainMod SHIFT, code:10, movetoworkspace, 1"
        "$mainMod SHIFT, code:11, movetoworkspace, 2"
        "$mainMod SHIFT, code:12, movetoworkspace, 3"
        "$mainMod SHIFT, code:13, movetoworkspace, 4"
        "$mainMod SHIFT, code:14, movetoworkspace, 5"
        "$mainMod SHIFT, code:15, movetoworkspace, 6"
        "$mainMod SHIFT, code:16, movetoworkspace, 7"
        "$mainMod SHIFT, code:17, movetoworkspace, 8"
        "$mainMod SHIFT, code:18, movetoworkspace, 9"
        "$mainMod SHIFT, code:19, movetoworkspace, 10"
        "$mainMod, XF86AudioMute, exec, playerctl play-pause"
        "$mainMod, XF86AudioLowerVolume, exec, playerctl previous"
        "$mainMod, XF86AudioRaiseVolume, exec, playerctl next"
        "$mainMod, L, exec, ${pkgs.hyprlock}/bin/hyprlock"
        "$mainMod SHIFT, R, exec, resources"
        "$mainMod SHIFT, C, exec, clipboard"
        "$mainMod SHIFT, T, exec, hyprpanel-toggle"
        "$mainMod,PRINT, exec, screenshot region"
        ",PRINT, exec, screenshot monitor"
        "$mainMod SHIFT,PRINT, exec, screenshot window"
        "ALT,PRINT, exec, screenshot region swappy"
      ];
      bindm = [
        "$mainMod,mouse:272, movewindow"
        "$mainMod,R, resizewindow"
      ];
      bindl = [
        ",switch:Lid Switch, exec, ${pkgs.hyprlock}/bin/hyprlock"
      ];

      bindle = [
        ",XF86AudioRaiseVolume, exec, sound-up"
        ",XF86AudioLowerVolume, exec, sound-down"
        ",XF86AudioMute, exec, sound-toggle"
        ",XF86MonBrightnessUp, exec, brightness-up"
        ",XF86MonBrightnessDown, exec, brightness-down"
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioPause, exec, playerctl play-pause"
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPrev, exec, playerctl previous"
      ];
    };
  };
}
