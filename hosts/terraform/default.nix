{...}: {
  my-services.networking.tailscale.tags = ["tag:managed-server" "tag:terraform"];
  profiles.lxc-base.enable = true;
  my-services.programs.terraform.enable = true;
}
