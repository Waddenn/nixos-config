{
  config,
  lib,
  ...
}: {
  options.steam.enable = lib.mkEnableOption "Enable steam";

  config = lib.mkIf config.steam.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };
  };
}
