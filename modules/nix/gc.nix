{
  config,
  lib,
  ...
}: {
  options.gc.enable = lib.mkEnableOption "gc";

  config = lib.mkIf config.gc.enable {
    nix.gc = {
      automatic = true;
      dates = "weekly";
      persistent = true;
      options = "--delete-older-than 14d";
    };
  };
}
