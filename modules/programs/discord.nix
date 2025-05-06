{
  config,
  lib,
  ...
}: let
  cfg = config.programs.discord;
in {
  options.programs.discord.enable = lib.mkEnableOption "Discord client";

  config = lib.mkIf cfg.enable {
    programs.nixcord = {
      enable = true;
      config = {frameless = true;};
    };
  };
}
