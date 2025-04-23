{
  config,
  lib,
  ...
}: {
  options.allowUnfree.enable = lib.mkEnableOption "Enable allowUnfree";

  config = lib.mkIf config.allowUnfree.enable {
    nixpkgs.config.allowUnfree = true;
  };
}
