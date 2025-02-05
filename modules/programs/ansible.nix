{ config, lib, pkgs, ... }:

{
  options = {
    ansible.enable = lib.mkEnableOption "Enable ansible";
  };

  config = lib.mkIf config.ansible.enable {
  environment.systemPackages = with pkgs; [
    ansible
  ]; 
  };
}