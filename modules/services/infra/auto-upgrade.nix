{
  config,
  lib,
  pkgs,
  ...
}: {
  options.autoUpgrade.enable = lib.mkEnableOption "Enable auto system upgrades";

  config = lib.mkIf config.autoUpgrade.enable {
    system.autoUpgrade = {
      enable = true;
      flake = "github:Waddenn/nixos-config";
      flags = [
        "--update-input"
        "nixpkgs"
        "-L" # print build logs
      ];
      dates = "04:00";
      randomizedDelaySec = "45min";
    };

    # Trust the binary cache (if we add one later like Cachix/Harmonia)
    # environment.systemPackages = [ pkgs.git ];
  };
}
