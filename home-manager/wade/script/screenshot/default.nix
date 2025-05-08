{pkgs, ...}: let
  screenshot = pkgs.writeShellScriptBin "screenshot" ''
    if [[ $2 == "swappy" ]]; then
      folder="/tmp"
    else
      folder="$HOME/Pictures"
    fi
    filename="$(date +%Y-%m-%d_%H:%M:%S).png"
    filepath="$folder/$filename"

    if [[ $1 == "region" ]]; then
      region="$(${pkgs.slurp}/bin/slurp)"
      ${pkgs.grim}/bin/grim -g "$region" "$filepath"
    elif [[ $1 == "window" ]]; then
      region="$(${pkgs.slurp}/bin/slurp -w 0)" # Window-like selection
      ${pkgs.grim}/bin/grim -g "$region" "$filepath"
    elif [[ $1 == "monitor" ]]; then
      output="$(${pkgs.grim}/bin/grim -l | head -n1 | awk '{print $1}')" # or pick dynamically
      ${pkgs.grim}/bin/grim -o "$output" "$filepath"
    else
      ${pkgs.grim}/bin/grim "$filepath" # fallback: full screen
    fi

    if [[ $2 == "swappy" ]]; then
      ${pkgs.swappy}/bin/swappy -f "$filepath" -o "$HOME/Pictures/$filename"
    fi
  '';
in {
  home.packages = [screenshot pkgs.grim pkgs.slurp pkgs.swappy];
}
