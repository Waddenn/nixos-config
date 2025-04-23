{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./home/packages.nix
    ./programs/git.nix
    ./desktopManager/gnome/background.nix
    ./desktopManager/gnome/extensions.nix
    ./desktopManager/gnome/favorite-apps.nix
    ./desktopManager/gnome/interface.nix
    ./desktopManager/gnome/keybindings.nix
    ./programs/fish.nix
  ];

  home.username = "tom";
  home.homeDirectory = "/home/tom";

  home.stateVersion = "24.05";

  programs.home-manager.enable = true;
}
