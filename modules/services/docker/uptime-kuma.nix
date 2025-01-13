{ config, pkgs, ... }:

{
  virtualisation.oci-containers.containers.uptime-kuma = {
    image = "louislam/uptime-kuma:latest";
    ports = [ "3001:3001" ];
    volumes = [ "/data/uptime-kuma:/app/data" ];
  };
}
