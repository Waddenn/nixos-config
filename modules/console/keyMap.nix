{ config, lib, ... }:

{
  options.keyMap.enable = lib.mkEnableOption "Enable keyMap";

  config = lib.mkIf config.keyMap.enable {
    console.keyMap = "fr";
  };
}
