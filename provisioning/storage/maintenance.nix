# Shared by the production fleet and provisioned pilots.
{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nix-storage-cleanup" ''
      export PATH=${lib.makeBinPath [pkgs.nix pkgs.coreutils]}:$PATH
      exec ${pkgs.python3}/bin/python3 ${./cleanup.py} "$@"
    '')
  ];
  nix = {
    settings = {
      auto-optimise-store = lib.mkDefault true;
      min-free = lib.mkDefault 1073741824;
      max-free = lib.mkDefault 3221225472;
    };
    gc = {
      automatic = true;
      persistent = true;
      dates = "daily";
      options = ""; # Retention is bounded by system generation count below.
    };
    optimise = {
      automatic = true;
      dates = ["03:15"];
    };
  };
  systemd.services.nix-gc.serviceConfig.ExecStart =
    lib.mkForce
    "${config.system.path}/bin/nix-storage-cleanup --prune";
}
