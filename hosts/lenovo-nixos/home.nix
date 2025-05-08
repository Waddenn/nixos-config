{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../home/programs/git.nix
    ../../home/programs/fish.nix
    ../../system/gnome/default.nix
  ];

  home.packages = with pkgs; [
    teams-for-linux
    remmina
    blanket
    papers
    whatip
    mullvad-browser
    resources
    dconf-editor
    trayscale
    youtube-music
    showtime
    libreoffice
    fastfetch
    miru
    brave
    foliate
    distrobox
    boxbuddy
    errands
    heroic
    gnome-boxes
  ];

  home.username = "tom";
  home.homeDirectory = "/home/tom";

  home.stateVersion = "24.05";

  programs.home-manager.enable = true;
}
