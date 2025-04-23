{
  config,
  lib,
  pkgs,
  ...
}: {
  options.terraform.enable = lib.mkEnableOption "Enable terraform";

  config = lib.mkIf config.terraform.enable {
    environment.systemPackages = with pkgs; [
      terraform
    ];
  };
}
