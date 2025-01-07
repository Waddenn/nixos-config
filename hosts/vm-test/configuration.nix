
{ config, pkgs, ... }:

{

  imports = [
    ../zramSwap/zramswap.nix
    ../services/tailscale.nix
    ../console/keyMap.nix
    ../i18n/i18n.nix
    ../networking/networkmanager.nix
    ../nix/settings.nix
    ../nixpkgs/config.nix
    ../time/timeZone.nix
    ../services/openssh.nix
    ../services/docker.nix
    ../boot/loader/grub.nix
  ];

  environment.systemPackages =  with pkgs; [
    git
    
  ];

}
