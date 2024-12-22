{ config, pkgs, ... }:
{
  ############################################
  # Gaming / Steam
  ############################################
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
  ];
}
