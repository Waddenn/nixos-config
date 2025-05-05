{
  config,
  pkgs,
  ...
}: {
  home.username = "wade";
  home.homeDirectory = "/home/wade";

  services.hyprland = {
    enable = true;
    settings = {
    };
  };

  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
}
