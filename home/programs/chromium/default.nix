{pkgs, ...}: {
  home.packages = with pkgs; [
    (writeShellScriptBin "chromium" ''
      exec "${pkgs.chromium}/bin/chromium" \
        --ozone-platform=wayland \
        --enable-features=UseOzonePlatform \
        --enable-wayland-ime \
        --gtk-version=4 \
        "$@"
    '')
  ];
}
