{
  config,
  lib,
  pkgs,
  ...
}: {
  options.my-services.programs.terraform.enable = lib.mkEnableOption "Enable terraform";

  config = lib.mkIf config.my-services.programs.terraform.enable {
    environment.systemPackages = with pkgs; [
      terraform
    ];
  };
}
