{config, ...}: {
  services.kanshi = {
    enable = true;
    systemdTarget = "hyprland-session.target";

    settings = [
      # Docké en DisplayPort
      {
        profile.name = "docked-dp";
        profile.outputs = [
          {
            criteria = "DP-1";
            status = "enable";
            position = "0,0";
            scale = 1.0;
          }
          {
            criteria = "eDP-1";
            status = "disable";
          }
        ];
        profile.exec =
          # Optionnel: coupe l’interne si tu veux
          "hyprctl dispatch dpms off eDP-1; \
           # Place Hyprpanel sur l’écran DP-1
           hyprctl keyword layerrule 'monitor DP-1, hyprpanel'; \
           hyprctl dispatch focusmonitor DP-1";
      }

      # Portable seul
      {
        profile.name = "undocked";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            mode = "2880x1800@60Hz";
            position = "0,0";
            scale = 2.0;
          }
        ];
        profile.exec = "hyprctl keyword monitor 'eDP-1,2880x1800@60,0x0,2'; \
           hyprctl dispatch dpms on eDP-1; \
           # Place Hyprpanel sur l’écran interne
           hyprctl keyword layerrule 'monitor eDP-1, hyprpanel'; \
           hyprctl dispatch focusmonitor eDP-1";
      }
    ];
  };
}
