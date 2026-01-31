{
  config,
  lib,
  ...
}: {
  options.my-services.networking.openssh.enable = lib.mkEnableOption "Enable openssh";

  config = lib.mkIf config.my-services.networking.openssh.enable {
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
      # settings.PermitRootLogin = "no"; # Commented as it might break some setups, verify usage? 
      # Original had "no". Restoring.
      settings.PermitRootLogin = "no";
    };
  };
}
