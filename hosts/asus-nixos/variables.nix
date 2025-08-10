{
  config,
  lib,
  ...
}: {
  imports = [
    ../../themes/catppuccin.nix
  ];

  config.var = {
    hostname = "asus-nixos";
    username = "tom";
    configDirectory =
      "/home/"
      + config.var.username
      + "/nixos-config/";

    keyboardLayout = "fr";

    location = "Paris";
    timeZone = "Europe/Paris";
    defaultLocale = "en_US.UTF-8";
    extraLocale = "fr_FR.UTF-8";

    git = {
      username = "Waddenn";
      email = "tpatelas@proton.me";
    };

    autoUpgrade = false;
    autoGarbageCollector = true;
  };

  # Let this here
  options = {
    var = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };
  };
}
