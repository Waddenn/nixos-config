{ config, lib, ... }:

{
  options = {
    firewall.enable = lib.mkEnableOption "Enable the firewall";
  };

  config = lib.mkIf config.firewall.enable {
    networking.firewall.enable = true;  
  };
}