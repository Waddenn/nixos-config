
{ ... }:

{

  imports = [

    ./hardware/bluetooth.nix
    ./networking/firewall.nix
    ./programs/firefox.nix
    ./system/autoUpgrade.nix

  ];

} 