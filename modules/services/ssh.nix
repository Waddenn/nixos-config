{ config, pkgs, ... }:

{

services.openssh = {
  enable = true;
  ports = [ 22 ];
  settings = {
    PasswordAuthentication = true;
    AllowUsers = null; 
    UseDns = true;
    X11Forwarding = false;
    PermitRootLogin = "prohibit-password"; 
  };
};

}



  

