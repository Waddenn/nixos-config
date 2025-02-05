{ config, lib, pkgs, ... }:

{

  users.users.nixos =
    {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILDWrexcT0dL92oAYuMxLpS+2WxBzwYA38C/paRGsZ2i tom@asus-nixos"
        
      ];
    };
    
  users.defaultUserShell = pkgs.zsh;

}
