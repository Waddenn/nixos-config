{
  pkgs,
  service,
  ...
}: {
  sops.secrets.demo-token.restartUnits = ["service-demo.service"];
  networking.firewall.allowedTCPPorts = [service.application.port];
  systemd.services.service-demo = {
    description = "Declarative provisioning demonstration";
    wantedBy = ["multi-user.target"];
    # sops-nix installs secrets during activation; LoadCredential fails closed if absent.
    environment = {
      PORT = toString service.application.port;
      SERVICE_NAME = service.name;
    };
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 ${./demo.py}";
      DynamicUser = true;
      LoadCredential = ["demo-token:/run/secrets/demo-token"];
      Restart = "on-failure";
      RestartSec = "2s";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
    };
  };
}
