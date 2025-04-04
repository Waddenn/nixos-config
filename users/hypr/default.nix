{ config, lib, pkgs, ... }:

{

  users.users.tom = {
    isNormalUser = true;
    description  = "Tom";
    extraGroups  = [ "networkmanager" "wheel" "lp" "scanner" "docker" "video" "audio" ];
    initialPassword = "password"; 
  };

  users.defaultUserShell = pkgs.zsh;
  
}
