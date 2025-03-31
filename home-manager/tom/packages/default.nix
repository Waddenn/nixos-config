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
    trayscale
    youtube-music
    showtime
    parabolic
    libreoffice
    fastfetch
    # errands
    librewolf
    miru
    brave
    foliate
    # pdfarranger
    # upscayl
  ];

}

