{
  config,
  lib,
  pkgs,
  ...
}: {
  options.my-services.programs.fish.enable = lib.mkEnableOption "Enable fish shell";

  config = lib.mkIf config.my-services.programs.fish.enable {
    programs.fish = {
      enable = true;

      shellInit = ''
        set -gx TERM xterm-256color
      '';
    };
  };
}
