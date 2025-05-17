{
  config,
  lib,
  ...
}: let
  foreground = "rgba(${config.theme.textColorOnWallpaper}ee)";
  font = config.stylix.fonts.serif.name;
in {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        grace = 5;
        no_fade_in = false;
        disable_loading_bar = false;
      };

      background = {
        monitor = "";
        blur_passes = 0;
        contrast = 0.8916;
        brightness = 0.7172;
        vibrancy = 0.1696;
        vibrancy_darkness = 0.0;
      };

      label = [
        {
          # Date
          monitor = "";
          text = ''cmd[update:1000] echo -e "$(date +"%A, %B %d")"'';
          color = foreground;
          font_size = 40;
          font_family = font + " Bold";
          position = "0, 540";
          halign = "center";
          valign = "center";
        }
        {
          # Time
          monitor = "";
          text = ''cmd[update:1000] echo "<span>$(date +"%H:%M")</span>"'';
          color = foreground;
          font_size = 220;
          font_family = "steelfish outline regular";
          position = "0, 370";
          halign = "center";
          valign = "center";
        }
        {
          # Username
          monitor = "";
          text = "    $USER";
          color = foreground;
          outline_thickness = 3;
          font_size = 42;
          font_family = font + " Bold";
          position = "0, -100";
          halign = "center";
          valign = "center";
        }
      ];

      input-field = lib.mkForce {
        monitor = "";
        size = "500, 100";
        outline_thickness = 3;
        dots_size = 0.2;
        dots_spacing = 0.2;
        dots_center = true;
        outer_color = "rgba(25, 25, 25, 0.2)";
        inner_color = "rgba(25, 25, 25, 0.25)";
        font_color = foreground;
        fade_on_empty = false;
        font_size = 38;
        font_family = font + " Bold";
        placeholder_text = "<i>🔒 Enter Password</i>";
        hide_input = false;
        position = "0, -220";
        halign = "center";
        valign = "center";
      };
    };
  };
}
