{ config, lib, pkgs, ... }:

{
  options.fish.enable = lib.mkEnableOption "Enable fish shell";

  config = lib.mkIf config.fish.enable {
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
        set -g fish_greeting "Bienvenue dans fish, Tom !"
        # Ajoute le chemin des binaires locaux
        set -U fish_user_paths $HOME/.local/bin $fish_user_paths
        # Active la complétion intelligente
        fish_config theme choose "Dracula"
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
  };
}
