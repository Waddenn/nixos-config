{
  lib,
  services ? import ./services.nix,
}: let
  names = builtins.attrNames services;
  values = builtins.attrValues services;
  unique = xs: builtins.length xs == builtins.length (lib.unique xs);
  valid = name: s:
    builtins.match "[a-z][a-z0-9_-]*" name
    != null
    && builtins.match "[a-z][a-z0-9-]*" s.hostname != null
    && s.environment == "pilot"
    && builtins.elem s.lifecycle ["active" "retained"]
    && builtins.isInt s.vmId
    && builtins.match "[A-Za-z][A-Za-z0-9_-]*" s.node != null
    && builtins.match "[A-Za-z][A-Za-z0-9_-]*" s.storage != null
    && builtins.match "[A-Za-z][A-Za-z0-9_-]*" s.bridge != null
    && s.vmId >= 100
    && s.vmId <= 999999999
    && s.cores > 0
    && s.memoryMiB >= 256
    && s.diskGiB >= 4
    && s.application.port > 1024
    && s.application.port < 65536
    && s.tailscaleTags != [];
in
  assert lib.assertMsg (unique (map (s: s.vmId) values)) "Duplicate Proxmox VM ID";
  assert lib.assertMsg (unique (map (s: s.hostname) values)) "Duplicate service hostname";
  assert lib.assertMsg (lib.all (name: valid name services.${name}) names) "Invalid service declaration";
    lib.mapAttrs (name: service:
      service
      // {
        inherit name;
        resourceAddress = "proxmox_virtual_environment_container.${name}";
        sshAlias = "service-${name}";
        secretFile = ./secrets + "/${name}.yaml";
        healthURL = "http://${service.hostname}:${toString service.application.port}${service.application.healthPath}";
      })
    services
