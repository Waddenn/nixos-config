# So best window tiling manager
{
  pkgs,
  config,
  inputs,
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
    ./bindings.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd = {
      enable = false;
      variables = [
        "--all"
      ]; # https://wiki.hyprland.org/Nix/Hyprland-on-Home-Manager/#programs-dont-work-in-systemd-services-but-do-on-the-terminal
    };
    package = null;
    portalPackage = null;

    settings = {
      "$mod" = "SUPER";
      "$shiftMod" = "SUPER_SHIFT";

      # exec-once = [
      #   "dbus-update-activation-environment --systemd --all &"
      #   "systemctl --user enable --now hyprpaper.service &"
      #   "systemctl --user enable --now hypridle.service &"
      #   "systemctl --user enable --now nextcloud-client.service  &"
      # ];

      monitor = [
        "eDP-1,preferred,auto,1.5"
      ];

      # cursor = {
      #   no_hardware_cursors = true;
      #   default_monitor = "eDP-2";
      # };

      # general = {
      #   resize_on_border = true;
      #   gaps_in = gaps-in;
      #   gaps_out = gaps-out;
      #   border_size = border-size;
      #   layout = "master";
      #   "col.inactive_border" = lib.mkForce background;
      # };

      # decoration = {
      #   active_opacity = active-opacity;
      #   inactive_opacity = inactive-opacity;
      #   rounding = rounding;
      #   shadow = {
      #     enabled = true;
      #     range = 20;
      #     render_power = 3;
      #   };
      #   blur = {
      #     enabled =
      #       if blur
      #       then "true"
      #       else "false";
      #     size = 18;
      #   };
      # };

      # master = {
      #   new_status = true;
      #   allow_small_split = true;
      #   mfact = 0.5;
      # };

      gestures = {workspace_swipe = true;};

      # misc = {
      #   vfr = true;
      #   disable_hyprland_logo = true;
      #   disable_splash_rendering = true;
      #   disable_autoreload = true;
      #   focus_on_activate = true;
      #   new_window_takes_over_fullscreen = 2;
      # };

      # windowrulev2 = [
      #   "float, tag:modal"
      #   "pin, tag:modal"
      #   "center, tag:modal"
      #   # telegram media viewer
      #   "float, title:^(Media viewer)$"

      #   # Bitwarden extension
      #   "float, title:^(.*Bitwarden Password Manager.*)$"

      #   # gnome calculator
      #   "float, class:^(org.gnome.Calculator)$"
      #   "size 360 490, class:^(org.gnome.Calculator)$"

      #   # make Firefox/Zen PiP window floating and sticky
      #   "float, title:^(Picture-in-Picture)$"
      #   "pin, title:^(Picture-in-Picture)$"

      #   # idle inhibit while watching videos
      #   "idleinhibit focus, class:^(mpv|.+exe|celluloid)$"
      #   "idleinhibit focus, class:^(zen)$, title:^(.*YouTube.*)$"
      #   "idleinhibit fullscreen, class:^(zen)$"

      #   "dimaround, class:^(gcr-prompter)$"
      #   "dimaround, class:^(xdg-desktop-portal-gtk)$"
      #   "dimaround, class:^(polkit-gnome-authentication-agent-1)$"
      #   "dimaround, class:^(zen)$, title:^(File Upload)$"

      #   # fix xwayland apps
      #   "rounding 0, xwayland:1"
      #   "center, class:^(.*jetbrains.*)$, title:^(Confirm Exit|Open Project|win424|win201|splash)$"
      #   "size 640 400, class:^(.*jetbrains.*)$, title:^(splash)$"
      # ];

      # layerrule = ["noanim, launcher" "noanim, ^ags-.*"];

      # input = {
      #   kb_layout = keyboardLayout;

      #   kb_options = "caps:escape";
      #   follow_mouse = 1;
      #   sensitivity = 0.5;
      #   repeat_delay = 300;
      #   repeat_rate = 50;
      #   numlock_by_default = true;

      #   touchpad = {
      #     natural_scroll = true;
      #     clickfinger_behavior = true;
      #   };
      # };
    };
  };
}
