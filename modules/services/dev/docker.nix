{
  config,
  lib,
  ...
}: {
  options.my-services.dev.docker.enable = lib.mkEnableOption "Enable docker";

  config = lib.mkIf config.my-services.dev.docker.enable {
    virtualisation.docker.enable = true;
  };
}
