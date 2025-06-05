{pkgs, ...}: {
  home.packages = with pkgs; [
    (pkgs.writeShellScriptBin "plex-desktop" ''
      exec ${pkgs.chromium}/bin/chromium \
        --app=https://app.plex.tv/desktop \
        --ozone-platform=wayland \
        --enable-features=VaapiVideoDecoder \
        --enable-zero-copy \
        --ignore-gpu-blocklist \
        --enable-gpu-rasterization
    '')
  ];
}
