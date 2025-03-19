{ config, lib, ... }:

{
  options.kubernetes.enable = lib.mkEnableOption "Enable kubernetes";

  config = lib.mkIf config.kubernetes.enable {

    services.kubernetes.roles = [ "master" "node" ];
    services.kubernetes.masterAddress = "localhost";

  };
}


