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
    ./wofi
    ./hyprpaper
    ./animation.nix
    ./hyprlock
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
    grim
    slurp
    swappy
    wl-clipboard
    qt5.qtwayland
    qt6.qtwayland
    libsForQt5.qt5ct
    qt6ct
    wayland-utils
    wayland-protocols
    pamixer
    brightnessctl
    playerctl
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
        "$mainMod,        space, exec, wofi --show drun"

        # Volume + OSD
        ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
        ", XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"
        ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"

        # Micro
        ", XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"

        # Luminosité + OSD
        ", XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
        ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"

        # Workspaces
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

        # Média
        "$mainMod, F1, exec, playerctl play-pause"
        "$mainMod, F2, exec, playerctl previous"
        "$mainMod, F3, exec, playerctl next"

        # Screenshots
        ", Print, exec, grim - | tee ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png | wl-copy"
        "$mainMod SHIFT, S, exec, slurp | grim -g - | tee ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png | wl-copy"
      ];
      bindl = [
        ",switch:Lid Switch, exec, ${pkgs.hyprlock}/bin/hyprlock" # Lock when closing Lid
      ];

      input = {
        kb_layout = "fr";

        kb_options = "caps:escape";
        follow_mouse = 1;
        repeat_delay = 300;
        repeat_rate = 50;
        numlock_by_default = true;

        touchpad = {
          natural_scroll = true;
          clickfinger_behavior = true;
        };
      };

      env = [
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "QT_QPA_PLATFORM,wayland"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "ELECTRON_OZONE_PLATFORM_HINT,wayland"
        "MOZ_ENABLE_WAYLAND,1"
        "SDL_VIDEODRIVER,wayland"
        "CLUTTER_BACKEND,wayland"
        "WLR_BACKEND,vulkan"
        "WLR_RENDERER,vulkan"
        "WLR_NO_HARDWARE_CURSORS,1"
        "XWAYLAND_SCALE,1"
      ];

      general = {
        resize_on_border = true;
        gaps_in = gaps-in;
        gaps_out = gaps-out;
        border_size = border-size;
        layout = "dwindle";
        "col.inactive_border" = lib.mkForce background;
      };

      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 3;
      };

      exec-once = [
        "systemctl --user enable --now hyprpaper.service &"
        "swayosd-server"
      ];

      misc = {
        vfr = true;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        disable_autoreload = true;
        focus_on_activate = true;
        new_window_takes_over_fullscreen = 2;
      };
      decoration = {
        active_opacity = active-opacity;
        inactive_opacity = inactive-opacity;
        rounding = rounding;
        shadow = {
          enabled = true;
          range = 20;
          render_power = 3;
        };
        blur = {
          enabled =
            if blur
            then "true"
            else "false";
          size = 18;
        };
      };

      windowrulev2 = [
        "float, tag:modal"
        "pin, tag:modal"
        "center, tag:modal"
        # telegram media viewer
        "float, title:^(Media viewer)$"

        # Bitwarden extension
        "float, title:^(.*Bitwarden Password Manager.*)$"

        # gnome calculator
        "float, class:^(org.gnome.Calculator)$"
        "size 360 490, class:^(org.gnome.Calculator)$"

        # make Firefox/Zen PiP window floating and sticky
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"

        # idle inhibit while watching videos
        "idleinhibit focus, class:^(mpv|.+exe|celluloid)$"
        "idleinhibit focus, class:^(zen)$, title:^(.*YouTube.*)$"
        "idleinhibit fullscreen, class:^(zen)$"

        "dimaround, class:^(gcr-prompter)$"
        "dimaround, class:^(xdg-desktop-portal-gtk)$"
        "dimaround, class:^(polkit-gnome-authentication-agent-1)$"
        "dimaround, class:^(zen)$, title:^(File Upload)$"

        # fix xwayland apps
        "rounding 0, xwayland:1"
        "center, class:^(.*jetbrains.*)$, title:^(Confirm Exit|Open Project|win424|win201|splash)$"
        "size 640 400, class:^(.*jetbrains.*)$, title:^(splash)$"
      ];

      layerrule = ["noanim, launcher" "noanim, ^ags-.*"];

      monitor = [
        "eDP-1,2880x1800@60,0x0,2"
      ];
    };
  };

  programs.git = {
    enable = true;
    userName = "Waddenn";
    userEmail = "tpatelas@proton.me";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  programs.fish = {
    enable = true;

    shellAliases = {
      ll = "ls -lh";
      la = "ls -lha";
      gs = "git status";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      k = "kubectl";
      d = "docker";
      tf = "terraform";
      cls = "clear";
      update = "nix flake update && sudo nixos-rebuild switch --flake .#$(hostname)";
    };

    interactiveShellInit = ''
      set -U fish_user_paths $HOME/.local/bin $fish_user_paths
      fish_config theme choose "Tomorrow Night Bright"
      set -g fish_greeting ""
    '';

    plugins = [
      {
        name = "z";
        src = pkgs.fishPlugins.z.src;
      }
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }
    ];
  };

  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
}
