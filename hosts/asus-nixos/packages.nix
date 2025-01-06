{ config, ... }:

{

  environment.systemPackages = [
    pkgs.vmware-workstation
  ];
  
}
