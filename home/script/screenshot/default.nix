{pkgs, ...}: let
  screenshot = pkgs.writeShellScriptBin "screenshot" ''
    folder="$HOME/Pictures"
    filename="$(date +%Y-%m-%d_%H:%M:%S).png"
    fullpath="$folder/$filename"

    case "$1" in
      "window")
        mode=(-m window)
        ;;
      "region")
        mode=(-m region)
        ;;
      "monitor")
        mode=(-m active -m output)
        ;;
      "active-window")
        mode=(-m active -m window)
        ;;
      *)
        echo "Usage: screenshot [region|window|monitor|active-window] [swappy]"
        exit 1
        ;;
    esac

    ${pkgs.hyprshot}/bin/hyprshot ''${mode[@]} -o "$folder" -f "$filename" || exit 1

    if [[ $2 == "swappy" ]]; then
      ${pkgs.swappy}/bin/swappy -f "$fullpath" -o "$folder/$filename"
    fi
  '';
in {
  home.packages = [
    screenshot
    pkgs.hyprshot
    pkgs.swappy
  ];
}
