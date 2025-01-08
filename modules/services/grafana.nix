{ config, ... }:

{
    
  services.grafana = {
    enable = true;
    settings = {
      server.http_addr = "0.0.0.0";  
      server.http_port = 3000;       
    };
  };

}
