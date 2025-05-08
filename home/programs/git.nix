{
  config,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;
    userName = "Waddenn";
    userEmail = "tpatelas@proton.me";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}
