{lib, ...}: {
  # Keep the live peer's name across activation and Tailscale refreshes.
  networking.hostName = lib.mkForce "valheim-server";
  profiles.lxc-base.enable = true;
  my-services.containers.valheim-server.enable = true;
}
