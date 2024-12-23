{ config, lib, pkgs, username, ... }:

{
  imports = [
    ../../modules/common/steam.nix
    ../../modules/common/firefox.nix
    ../../modules/common/base.nix
    ../../modules/desktop/gnome/base.nix
    ../../modules/services/flatpak.nix
    ../../modules/services/printing.nix
    ../../modules/services/pipewire.nix
    ../../modules/services/tailscale.nix
    ../../modules/services/fwupd.nix
  ];

  users.users.${username} = {
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
