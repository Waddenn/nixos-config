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
  background = "rgb(" + config.lib.stylix.colors.base00 + ")";
in {
  imports = [
    ./bindings.nix
    ./animation.nix
    ./polkitagent.nix
  ];

  home.packages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland
    libsForQt5.qt5ct
    qt6ct
    hyprshot
    hyprpicker
    swappy
    imv
    wf-recorder
    wlr-randr
    wl-clipboard
    brightnessctl
    gnome-themes-extra
    libva
    dconf
    wayland-utils
    wayland-protocols
    glib
    direnv
    meson
  ];

  dconf.settings = {
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "";
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd = {
      enable = false;
      variables = [
        "--all"
      ];
    };
    package = null;
    portalPackage = null;
    settings = {
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

        "GDK_BACKEND,wayland"
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
        "XCURSOR_SIZE=24"
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
        "dbus-update-activation-environment --systemd --all &"
        "systemctl --user enable --now hyprpaper.service &"
        "systemctl --user enable --now hypridle.service &"
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

        "workspace 1 silent, class:^(firefox)$"
        "workspace 2 silent, class:^(code)$"
        "workspace 4 silent, class:^(com.github.th_ch.youtube_music)$"
        "workspace 5 silent, class:^(discord)$"
      ];
      layerrule = ["noanim, launcher" "noanim, ^ags-.*"];
      monitor = [
        "eDP-1,2880x1800@60,0x0,2"
        "HDMI-A-1,preferred,2880x0,1"
      ];
    };
  };
}
