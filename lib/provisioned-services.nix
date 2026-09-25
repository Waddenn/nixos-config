# Projection of the common declarations, never a second service inventory.
{lib}: let
  inventory = import ../provisioning/inventory.nix {inherit lib;};
  services = lib.filterAttrs (_: s: s.gitops.enable) inventory;
  active = lib.filterAttrs (_: s: s.lifecycle == "active") services;
  tailnet = (import ../modules/data/beszel-hosts.nix).tailnet;
  proxyHost = "caddy.${tailnet}";
  proxyPort = 8085;
  proxyServices = lib.filterAttrs (_: s: s.gitops.internalProxy) active;
  identity = s: builtins.fromJSON (builtins.readFile (../provisioning/identities + "/${s.name}.json"));
in {
  inherit services active tailnet proxyHost proxyPort identity;
  byHost = lib.mapAttrs' (_: s: lib.nameValuePair s.hostname s) services;
  endpoints =
    (lib.mapAttrsToList (name: s: {
        inherit name;
        group = "declared-services";
        url = "http://${s.hostname}.${tailnet}:${toString s.application.port}${s.application.healthPath}";
        conditions = s.application.conditions;
        interval = "30s";
      })
      active)
    ++ lib.mapAttrsToList (name: s: {
      name = "${name}-proxy";
      group = "declared-services";
      url = "http://${proxyHost}:${toString proxyPort}/${name}${s.application.healthPath}";
      conditions = s.application.conditions;
      interval = "30s";
    })
    proxyServices;
  inherit proxyServices;
}
