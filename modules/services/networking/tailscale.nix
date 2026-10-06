{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my-services.networking.tailscale;
  tagPrefs = pkgs.writeText "tailscale-tag-prefs.json" (builtins.toJSON {
    AdvertiseTags = cfg.tags;
    AdvertiseTagsSet = true;
  });
in {
  options.my-services.networking.tailscale = {
    enable = lib.mkEnableOption "Tailscale Service";
    role = lib.mkOption {
      type = lib.types.enum ["client" "server"];
      default = "client";
      description = "Tailscale routing role";
    };
    extraSetFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Persistent Tailscale settings; does not reset unspecified preferences.";
    };
    tags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = lib.optional (cfg.role == "server") "tag:managed-server";
      description = "Server identities owned by tailnet admins; personal clients stay user-owned.";
    };
    authKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/run/secrets/tailscale/Client-secret";
      description = "Path to auth key (for client)";
    };
  };

  config = lib.mkIf config.my-services.networking.tailscale.enable {
    # Fleet activations are transported over Tailscale SSH. Restarting this unit
    # inside switch-to-configuration kills the SSH scope and leaves the target
    # only partially activated. The deployer performs a detached refresh after
    # Colmena has returned and then waits for connectivity and health again.
    systemd.services.tailscaled = {
      stopIfChanged = false;
      restartIfChanged = false;
    };

    # Tags are absent from `tailscale set` in 1.102.5. Patch only this preference
    # through the same local API as the CLI, preserving routes, DNS and SSH.
    systemd.services.tailscale-tags = lib.mkIf (cfg.tags != []) {
      after = ["tailscaled.service" "tailscaled-autoconnect.service" "tailscaled-set.service"];
      requires = ["tailscaled.service"];
      wantedBy = ["tailscaled.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.curl}/bin/curl --fail --silent --show-error --max-time 20 --retry 5 --retry-connrefused --retry-delay 1 --unix-socket /run/tailscale/tailscaled.sock --request PATCH --header Content-Type:application/json --data-binary @${tagPrefs} --output /dev/null http://local-tailscaled.sock/localapi/v0/prefs";
      };
    };

    services.tailscale = {
      enable = true;
      openFirewall = true;
      extraSetFlags = cfg.extraSetFlags;
      useRoutingFeatures = config.my-services.networking.tailscale.role;
      # Conditionally set authKeyFile only if client?
      # Original client used it. Server didn't.
      # Ideally we use logic here.
      authKeyFile =
        if config.my-services.networking.tailscale.role == "client"
        then config.my-services.networking.tailscale.authKeyFile
        else null;
      extraUpFlags =
        if config.my-services.networking.tailscale.role == "server"
        then ["--ssh"]
        else [];
    };
  };
}
