{ config, lib, ... }:

{
  options.zsh.enable = lib.mkEnableOption "Enable zsh";

  config = lib.mkIf config.zsh.enable {

  programs = {
    zsh = {
      enable = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;
      ohMyZsh = {
        enable = true;
        theme = "agnoster";
        plugins = [
	        "git"
          "kubectl"
          "docker"
        ];
      };
    };
  };

  };
}
