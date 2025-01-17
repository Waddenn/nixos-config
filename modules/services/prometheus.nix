{ config, lib, ... }:

{
  options = {
    prometheus.enable = lib.mkEnableOption "Enable prometheus";
  };

  config = lib.mkIf config.prometheus.enable {

  # https://wiki.nixos.org/wiki/Prometheus
  # https://nixos.org/manual/nixos/stable/#module-services-prometheus-exporters-configuration
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/default.nix
  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "10s"; 
    scrapeConfigs = [
    {
      job_name = "node";
      static_configs = [{
        targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
      }];
    }
    ];
  };

  networking.firewall.allowedTCPPorts = [ 9090 9100 ];
  };
}