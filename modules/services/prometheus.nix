{ config, ... }:

{
    
  services.prometheus = {
    enable = true;
    configText = ''
      global:
        scrape_interval: 15s

      scrape_configs:
        - job_name: 'prometheus'
          static_configs:
            - targets: ['localhost:9090']
    '';
  };

}
