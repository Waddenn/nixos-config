{ config, lib, pkgs, ... }:

{
  options.fprintd.enable = lib.mkEnableOption "Enable fprintd";

  config = lib.mkIf config.fprintd.enable {

  services.fprintd.tod.enable = true;
  services.fprintd.tod.driver = pkgs.libfprint-2-tod1-vfs0090;

  };
}
