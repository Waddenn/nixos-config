{
  config,
  lib,
  ...
}: {
  options.my-services.dev.kubernetes.enable = lib.mkEnableOption "Enable kubernetes";

  config = lib.mkIf config.my-services.dev.kubernetes.enable {
    services.kubernetes.roles = ["master" "node"];
    services.kubernetes.masterAddress = "localhost";

    services.etcd = {
      initialClusterToken = "etcd-cluster-1";
    };
  };
}
