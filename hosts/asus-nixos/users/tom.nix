{ config, lib, pkgs, ... }:

{

  users.users.tom = {
    isNormalUser = true;
    description  = "Tom";
    extraGroups  = [ "networkmanager" "wheel" "lp" "scanner" ];
  };

  programs.git = {
    enable = true;
    userName  = "waddenn";
    userEmail = "waddenn.github@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

}
