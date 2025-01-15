{ config, ... }:

{
  options = {
    networking.firewall.enable = lib.mkEnableOption "Enable the firewall";
  };

  config = lib.mkIf config.networking.firewall.enable {
    networking.firewall.enable = true;  
  };
}