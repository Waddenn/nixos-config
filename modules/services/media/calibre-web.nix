{
  config,
  lib,
  ...
}: {
  options.my-services.media."calibre-web".enable = lib.mkEnableOption "Enable Calibre-Web service";

  config = lib.mkIf config.my-services.media."calibre-web".enable {
    services.calibre-web = {
      enable = true;
      openFirewall = true;
      options = {
        enableBookUploading = true;
        enableBookConversion = true;
      };
    };
  };
}
