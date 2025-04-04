{
  programs.hyprland.enable = true;

  environment.systemPackages = with pkgs; [
    hyprland
    waybar                 # barre système (optionnel mais recommandé)
    wofi                   # launcher d'applis
    alacritty              # terminal
    kitty                  # ou un autre terminal si tu préfères
    wl-clipboard           # copier/coller sous Wayland
    xdg-utils              # pour ouvrir les liens
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
  ];

  # Pour s'assurer que le bon portail est utilisé
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };
}
