{ config, ... }:

{

  programs = {
    zsh = {
      enable = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
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

}