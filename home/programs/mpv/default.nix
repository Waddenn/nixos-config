{
  config,
  pkgs,
  ...
}: {
  programs.mpv = {
    enable = true;
    config = {
      vo = "gpu";
      gpu-api = "opengl";
    };
  };
}
