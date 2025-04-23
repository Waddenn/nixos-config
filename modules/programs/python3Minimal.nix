{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    python3Minimal.enable = lib.mkEnableOption "Enable python3Minimal";
  };

  config = lib.mkIf config.python3Minimal.enable {
    environment.systemPackages = with pkgs; [
      python3Minimal
    ];
  };
}
