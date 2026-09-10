{...}: {
  profiles.lxc-base.enable = true;
  my-services.infra.pull-updater.enable = true;
  my-services.infra.deployer-node.enable = true;
}
