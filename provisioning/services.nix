# Single declaration: infrastructure, OS, application and health share this identity.
{
  prototype = {
    environment = "pilot";
    hostname = "nixos-provisioning-prototype";
    vmId = 9901;
    node = "proxade";
    storage = "Storage2";
    cores = 1;
    memoryMiB = 512;
    diskGiB = 4;
    bridge = "vmbr0";
    ipv4 = "dhcp";
    lifecycle = "active"; # "retained" keeps the CT but excludes it from activation.
    application = {
      module = ./applications/demo.nix;
      port = 8080;
      healthPath = "/healthz";
      units = ["service-demo.service"];
      healthBody = {status = "ready";};
      conditions = ["[STATUS] == 200" "[BODY].status == ready"];
      generatedSecrets = ["demo-token"];
      secretProbe = {
        secret = "demo-token";
        path = "/private";
        header = "X-Demo-Token";
        expected = {authenticated = true;};
      };
    };
    tailscaleTags = ["tag:nixos-pilot"];
    monitoring = true; # A pilot-local Gatus instance; no production inventory change.
  };
}
