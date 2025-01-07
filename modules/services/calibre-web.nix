{ config, ... }:

{

  services.calibre-web= {
    enable = true;
    options = {
      calibreLibrary = "~/Downloads/ebook";
      enableBookUploading = true;
      enableBookConversion = true;
    };
  };
  
}
