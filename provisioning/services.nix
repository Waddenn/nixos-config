# Single declaration: infrastructure, OS, application and health share this identity.
{
  classeur = {
    # VMID/resources must be audited on the live cluster before provisioning.
    gitops = {
      enable = false;
      canary = false;
      internalProxy = false;
    };
    environment = "pilot";
    hostname = "nixos-classeur";
    vmId = 9903;
    node = "proxade";
    storage = "Storage2";
    cores = 4;
    memoryMiB = 8192;
    diskGiB = 64;
    startOnBoot = true; # Apply with the explicit, narrowly guarded autostart action.
    bridge = "vmbr0";
    ipv4 = "dhcp";
    lifecycle = "active";
    application = {
      module = ./applications/classeur.nix;
      port = 8084; # nginx ingress; Node stays on 127.0.0.1:8083.
      healthPath = "/health";
      units = ["postgresql.service" "nginx.service" "le-classeur.service"];
      healthBody = {status = "ok";};
      conditions = ["[STATUS] == 200" "[BODY].status == ok"];
      # OAuth/session/Turnstile values must be supplied, never randomly replaced.
      generatedSecrets = [];
    };
    tailscaleTags = ["tag:nixos-pilot"];
    monitoring = true;
  };
  prototype = {
    environment = "pilot";
    hostname = "nixos-provisioning-prototype";
    vmId = 9901;
    node = "proxade";
    storage = "Storage2";
    cores = 1;
    memoryMiB = 512;
    diskGiB = 16;
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
  probe = {
    # Proposed main-fleet ownership: effective only after reviewed merge + exact main CI.
    gitops = {
      enable = true;
      canary = true;
      internalProxy = true;
    };
    environment = "pilot";
    hostname = "nixos-service-probe";
    vmId = 9902;
    node = "proxade";
    storage = "Storage2";
    cores = 1;
    memoryMiB = 512;
    diskGiB = 16;
    bridge = "vmbr0";
    ipv4 = "dhcp";
    lifecycle = "active"; # "retained" keeps the CT but excludes it from activation.
    application = {
      module = ./applications/demo.nix;
      port = 8082;
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
