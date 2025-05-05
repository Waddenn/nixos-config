{
  config,
  pkgs,
  ...
}: {
  home.username = "wade";
  home.homeDirectory = "/home/wade";

  wayland.windowsManager.hyprland = {
    enable = true;
    setting = {
      
    }
  }

  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
}
