{ config, lib, pkgs, hostname, ... }:

{
  imports = [

  ];

  networking.hostName = ${hostname};

  system.stateVersion = "25.05";


}
