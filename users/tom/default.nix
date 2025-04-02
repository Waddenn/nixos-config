{ config, lib, pkgs, ... }:

{

  users.users.tom = {
    isNormalUser = true;
    description  = "Tom";
    extraGroups  = [ "networkmanager" "wheel" "lp" "scanner" "docker"];
    initialPassword = "password"; 
  };

  users.defaultUserShell = pkgs.zsh;
  
}
