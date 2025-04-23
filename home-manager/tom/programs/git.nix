{
  config,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;
    userName = "waddenn";
    userEmail = "waddenn.github@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}
