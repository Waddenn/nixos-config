{
  config,
  pkgs,
  ...
}: {
  home.username = "wade";
  home.homeDirectory = "/home/wade";
  home.packages = with pkgs; [
    kitty
    firefox
  ];
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    settings = {
      "$mainMod" = "SUPER";
      bind = [
        "$mainMod,        Return, exec, kitty"
        "$mainMod,        d, exec, $menu --show drun"
        "$mainMod,        q, killactive,"
        "$mainMod SHIFT,  q, exit,"
        "$mainMod,        f, togglefloating,"
        "$mainMod SHIFT,  c, killactive,"
        "$mainMod,        e, exec, $fileManager"
        "$mainMod,        v, exec, cliphist list | $menu --dmenu | cliphist decode | wl-copy"
        "$mainMod,        l, exec, loginctl lock-session"
        "$mainMod,        p, exec, hyprpicker -an"
        "$mainMod,        b, exec, pkill -SIGUSR2 waybar"
        "$mainMod SHIFT,  b, exec, pkill -SIGUSR1 waybar"
        "$mainMod,        n, exec, swaync-client -t"
        "$mainMod,        j, togglesplit,"
        "$mainMod SHIFT,  e, exec, bemoji -cn"
        "$mainMod,        r, exec, hyprctl reload"
      ];
    };
  };

  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
}
