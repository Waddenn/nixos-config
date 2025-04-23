{config, ...}: {
  services.calibre-web = {
    enable = true;
    openFirewall = true;
    options = {
      enableBookUploading = true;
      enableBookConversion = true;
    };
  };
}
