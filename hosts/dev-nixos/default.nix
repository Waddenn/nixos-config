{...}: {
  my-services.networking.tailscale.tags = ["tag:managed-server" "tag:gitops-controller"];
  profiles.lxc-base.enable = true;
  my-services.infra.pull-updater.enable = true;
  my-services.infra.deployer-node.enable = true;
}
