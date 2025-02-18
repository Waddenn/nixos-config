{ config, lib, pkgs, ... }:

{
  options.vaultwarden.enable = lib.mkEnableOption "Enable vaultwarden";

  config = lib.mkIf config.vaultwarden.enable {

  services.vaultwarden.enable = true;

  };
}
