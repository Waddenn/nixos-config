{
  config,
  pkgs,
  ...
}: {
  home.username = "hypruser";
  home.homeDirectory = "/home/hypruser";

  programs.home-manager.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = ",preferred,auto,1";
      exec-once = "foot";
      input.kb_layout = "fr";
    };
  };

  programs.waybar.enable = true;
  programs.foot.enable = true;
  programs.zsh.enable = true;

  services.mako.enable = true;

  home.packages = with pkgs; [
    hyprpaper
    kitty
    firefox
    wl-clipboard
    grim
    slurp
    swaylock-effects
    wofi
  ];

  home.stateVersion = "25.05";
}
