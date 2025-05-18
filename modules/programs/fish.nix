{
  config,
  lib,
  pkgs,
  ...
}: {
  options.fish.enable = lib.mkEnableOption "Enable fish shell";

  config = lib.mkIf config.fish.enable {
    programs.fish = {
      enable = true;

      shellInit = ''
        set -gx TERM xterm-256color
      '';
    };
  };
}
