#zsh.nix

{ config, pkgs, ... }:

let
  zsh_plugins = import ./zsh_plugins.nix { inherit pkgs; };
in
{
  programs.zsh = {
    enable = true;
    plugins = with zsh_plugins; plugin_list;

    shellInit = ''
      autoload -U promptinit; promptinit
    '';

    interactiveShellInit = ''
      source ${pkgs.zsh-nix-shell}/share/zsh-nix-shell/nix-shell.plugin.zsh
      source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
      source ${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh

      # Docker aliases
      alias dps='docker ps'
      alias dlogs='docker logs'
      alias dbuild='docker build'

      # Terraform aliases
      alias tf='terraform'
      alias tfi='terraform init'
      alias tfp='terraform plan'
      alias tfa='terraform apply'
    '';
  };
}
