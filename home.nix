{ config, pkgs, ... }:

{
  home.username = "tom";
  home.homeDirectory = "/home/tom";
  
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

  programs.git = {
    enable = true;
    userName  = "waddenn";
    userEmail = "waddenn.github@gmail.com";
  };

  programs.firefox = {
    enable = true;                    
  };

  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "firefox.desktop"
        "org.gnome.Console.desktop"
        "vesktop.desktop"
        "org.remmina.Remmina.desktop"
        "youtube-music.desktop"
      ];
      disable-user-extensions = false;
      remember-mount-password = true;
      enabled-extensions = [
        "hidetopbar@mathieu.bidon.ca"
        "tailscale@joaophi.github.com"
        "AlphabeticalAppGrid@stuarthayhurst"
        "appindicatorsupport@rgcjonas.gmail.com"
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
        "Battery-Health-Charging@maniacx.github.com"
        "search-light@icedman.github.com"
        "blur-my-shell@aunetx"
      ];
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      clock-show-weekday = true;
      accent-color = "slate";
    };

    "org.gnome.system.locale" = {
      custom-value = "fr_FR.UTF-8";
    };

    "org/gnome/desktop/wm/keybindings" = {
      minimize = [ "<Super>h" ];
      show-desktop = [ "<Super>d" ];
      toggle-fullscreen = [ "<Super>f" ];
      close = [ "<Super>q" "<Alt>F4" ];
      switch-to-workspace-left = [ "<Alt>Left" ];
      switch-to-workspace-right = [ "<Alt>Right" ];
      switch-to-workspace-1 = [ "<Alt>1" ];
      switch-to-workspace-2 = [ "<Alt>2" ];
      switch-to-workspace-3 = [ "<Alt>3" ];
      switch-to-workspace-4 = [ "<Alt>4" ];
      switch-to-workspace-5 = [ "<Alt>5" ];
      move-to-workspace-left = [ "<Ctrl><Alt>Left" ];
      move-to-workspace-right = [ "<Ctrl><Alt>Right" ];
      move-to-workspace-1 = [ "<Ctrl><Alt>1" ];
      move-to-workspace-2 = [ "<Ctrl><Alt>2" ];
      move-to-workspace-3 = [ "<Ctrl><Alt>3" ];
      move-to-workspace-4 = [ "<Ctrl><Alt>4" ];
      move-to-workspace-5 = [ "<Ctrl><Alt>5" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
      ];
      control-center = [ "<Super>i" ];
      home = [ "<Super>e" ];
      next = [ "<Super>AudioRaiseVolume" ];
      play = [ "<Super>AudioMute" ];
      previous = [ "<Super>AudioLowerVolume" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Control><Alt>t";
      command = "kgx";
      name = "open-terminal";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "<Shift><Control>Escape";
      command = "resources";
      name = "Resources";
    };

    "org/gnome/shell/extensions/system-monitor" = {
      show-cpu = true;
      show-download = false;
      show-memory = true;
      show-swap = true;
      show-upload = false;
    };

    "org/gnome/shell/extensions/Battery-Health-Charging" = {
      amend-power-indicator = true;
      charging-mode = "max";
      show-battery-panel2 = false;
      show-preferences = false;
      show-system-indicator = false;
    };
  };

  # Version de l'état Home Manager
  home.stateVersion = "24.05";

  # Activation de Home Manager
  programs.home-manager.enable = true;
}
