{ config, pkgs, ... }:

{
  virtualisation.oci-containers = {
    backend = "docker"; 
    containers = {
      adguard-home = {
        image = "adguard/adguardhome:latest"; 
        ports = [ 
          "3000:3000" 
          "53:53"     
          "53:53/udp" 
          "80:80"     
          "443:443"  
        ];
        volumes = [
          "/data/adguard/config:/opt/adguardhome/conf" 
          "/data/adguard/work:/opt/adguardhome/work"   
        ];
        environment = { 
          TZ = "Europe/Paris"; 
        };
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 3000 53 80 443 ]; 
    allowedUDPPorts = [ 53 ];             
  };
}
