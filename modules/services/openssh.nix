{
  config,
  lib,
  ...
}: {
  options.openssh.enable = lib.mkEnableOption "Enable openssh";

  config = lib.mkIf config.openssh.enable {
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
      settings.PermitRootLogin = "no";
    };
  };
}
