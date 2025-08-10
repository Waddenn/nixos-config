# home/programs/kanshi/default.nix
{config, ...}: {
  # Option A — garder systemd.enable = false dans Hyprland :
  services.kanshi = {
    enable = true;
    # hyprland-session.target n’existe pas si tu as désactivé systemd côté Hyprland
    systemdTarget = "graphical-session.target";
    settings = [
      {
        profile.name = "docked";
        profile.outputs = [
          # Vérifie les noms exacts avec: hyprctl monitors all
          {
            criteria = "DP-2";
            mode = "3440x1440@144";
            position = "0,0";
            scale = 1.0;
          }
          {
            criteria = "eDP-1";
            status = "disable";
          }
        ];
      }
      {
        profile.name = "undocked";
        profile.outputs = [
          {
            criteria = "eDP-1";
            mode = "2880x1800@60";
            position = "0,0";
            scale = 2.0;
          }
        ];
      }
    ];
  };
}
