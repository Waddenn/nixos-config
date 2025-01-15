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
    resources
    dconf-editor
    vesktop
    trayscale
    youtube-music
    showtime
    parabolic
    libreoffice
    fastfetch
    errands
    # pdfarranger
    # librewolf
    # upscayl
  ];

}

