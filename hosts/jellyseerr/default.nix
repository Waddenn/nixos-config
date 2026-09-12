{...}: {
  profiles.lxc-base.enable = true;
  # Keep this host name stable: it is also the LXC and deployment identity.
  my-services.media.seerr.enable = true;
}
