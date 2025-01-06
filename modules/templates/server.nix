 { config, ... }:

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
    ../services/ssh.nix
    ../boot/loader/grub.nix
  ];

}
