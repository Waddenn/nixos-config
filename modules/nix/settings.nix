{ config, lib, ... }:

{
  options.experimental-features.enable = lib.mkEnableOption "Enable experimental-features";

  config = lib.mkIf config.experimental-features.enable {

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  };
}
