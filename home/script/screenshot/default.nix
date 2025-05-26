{pkgs, ...}: let
  screenshot = pkgs.writeShellScriptBin "screenshot" ''
    folder="$HOME/Pictures"
    filename="$(date +%Y-%m-%d_%H:%M:%S).png"
    fullpath="$folder/$filename"

    case "$1" in
      "window") mode="window" ;;
      "region") mode="area" ;;
      "monitor") mode="output" ;;
      "active-window") mode="active" ;;
      *) echo "Usage: screenshot [region|window|monitor|active-window] [swappy]"; exit 1 ;;
    esac

    if [[ $2 == "swappy" ]]; then
      ${pkgs.grimblast}/bin/grimblast --notify --freeze copysave "$mode" "$fullpath"
      ${pkgs.swappy}/bin/swappy -f "$fullpath" -o "$fullpath"
    else
      ${pkgs.hyprshot}/bin/hyprshot -m "$mode" -o "$folder" -f "$filename"
    fi
  '';
in {
  home.packages = [
    screenshot
    pkgs.hyprshot
    pkgs.grimblast
    pkgs.swappy
  ];
}
