{
  config,
  pkgs,
  lib,
  ...
}: let
  border-size = config.theme.border-size;
  gaps-in = config.theme.gaps-in;
  gaps-out = config.theme.gaps-out;
  active-opacity = config.theme.active-opacity;
  inactive-opacity = config.theme.inactive-opacity;
  rounding = config.theme.rounding;
  blur = config.theme.blur;
  keyboardLayout = config.var.keyboardLayout;
  background = "rgb(" + config.lib.stylix.colors.base00 + ")";
in {
  imports = [
    ../../home/system/wofi
    ../../home/system/hyprpaper
    ../../home/system/clipman
    ../../home/system/hyprpanel
    # ../../home/system/hyprland/hyprspace.nix
    ../../home/system/hyprlock
    ../../home/system/zathura
    ../../home/script
    ../../home/system/hyprland
    ../../home/system/udiskie
    ../../home/system/hypridle
    ../../home/system/mime
    ../../home/programs/thunar
    ../../home/programs/nextcloud
    ../../themes/nixy.nix
    ../../modules/programs/fzf.nix
  ];
  home.username = "tom";
  home.homeDirectory = "/home/tom";
  home.packages = with pkgs; [
  ];

  programs.kitty = {
    enable = true;
    extraConfig = ''
      confirm_os_window_close 0
    '';
  };

  programs.git = {
    enable = true;
    userName = "Waddenn";
    userEmail = "tpatelas@proton.me";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  programs.fish = {
    enable = true;

    shellAliases = {
      ll = "ls -lh";
      la = "ls -lha";
      gs = "git status";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      k = "kubectl";
      d = "docker";
      tf = "terraform";
      cls = "clear";
      update = "nix flake update && sudo nixos-rebuild switch --flake .#$(hostname)";
    };

    interactiveShellInit = ''
      set -U fish_user_paths $HOME/.local/bin $fish_user_paths
      fish_config theme choose "Tomorrow Night Bright"
      set -g fish_greeting ""
    '';

    plugins = [
      {
        name = "z";
        src = pkgs.fishPlugins.z.src;
      }
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }
    ];
  };

  # file.".face.icon" = {source = ./profile_picture.png;};

  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
}
