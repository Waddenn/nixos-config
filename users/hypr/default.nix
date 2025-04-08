{ config, lib, pkgs, ... }:

{

  users.users.hypr = {
    isNormalUser = true;
    description  = "hypr";
    extraGroups  = [ "networkmanager" "wheel" "lp" "scanner" "docker" "video" "audio" ];
    initialPassword = "password"; 
  };

  users.defaultUserShell = pkgs.zsh;
  
}
