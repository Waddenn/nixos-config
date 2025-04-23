{
  config,
  lib,
  inputs,
  ...
}: {
  options.autoUpgrade.enable = lib.mkEnableOption "Enable system auto-upgrade";

  config = lib.mkIf config.autoUpgrade.enable {
    system.autoUpgrade = {
      enable = true;
      dates = "daily";
      flake = inputs.self.outPath;
      flags = ["--update-input" "nixpkgs" "-L"];
      persistent = true;
    };
  };
}
