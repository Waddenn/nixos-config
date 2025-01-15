
{ config, pkgs, ... }:

{

  imports = [
    ../../modules/zramSwap/zramswap.nix
    ../../modules/services/tailscale.nix
    ../../modules/console/keyMap.nix
    ../../modules/i18n/i18n.nix
    ../../modules/networking/networkmanager.nix
    ../../modules/nix/settings.nix
    ../../modules/nixpkgs/config.nix
    ../../modules/time/timeZone.nix
    ../../modules/services/openssh.nix
    ../../modules/services/docker.nix
    ../../modules/boot/loader/grub.nix
    ../../modules/programs/zsh.nix

  ];

  environment.systemPackages =  with pkgs; [
    git

  ];

}
