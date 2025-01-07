{ config, pkgs, ... }:

{

  home.packages = with pkgs; [ 
    teams-for-linux
    remmina
    obsidian
    blanket
    papers
    whatip
    vscode
    mullvad-browser
    ciscoPacketTracer8
    gnome-software
    resources
    dconf-editor
    vesktop
    trayscale
    youtube-music
    showtime
    parabolic
    libreoffice
    fastfetch
    vim
    # pdfarranger
    # librewolf
    # upscayl
  ];

}

