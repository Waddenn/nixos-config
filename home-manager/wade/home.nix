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
        # Screenshot shortcuts
        ", Print, exec, grim - | tee ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png | wl-copy"
        "$mainMod SHIFT, S, exec, slurp | grim -g - | tee ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png | wl-copy"
      ];

      input = {
        kb_layout = "fr";
        touchpad = {
          natural_scroll = true;
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
        layout = "master";
        "col.inactive_border" = lib.mkForce background;
      };

      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 3;
      };

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
