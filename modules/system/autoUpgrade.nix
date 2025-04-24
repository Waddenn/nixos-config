{
  config,
  lib,
  inputs,
  ...
}: {
  options = {
    autoUpgrade.enable = lib.mkEnableOption "Enable system auto-upgrade";
    autoUpgrade.updateFlakeLock = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow autoUpgrade to update flake.lock (use --update-input nixpkgs)";
    };
  };

  config = lib.mkIf config.autoUpgrade.enable {
    system.autoUpgrade = {
      enable = true;
      dates = "daily";
      flake = inputs.self.outPath;
      flags =
        if config.autoUpgrade.updateFlakeLock
        then ["--update-input" "nixpkgs" "-L"]
        else ["-L"];
      persistent = true;
    };
  };
}
