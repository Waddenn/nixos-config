{
  config,
  lib,
  ...
}: {
  options.pipewire.enable = lib.mkEnableOption "Enable pipewire";

  config = lib.mkIf config.pipewire.enable {
    services.pipewire = {
      enable = true;

      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    services.pulseaudio.enable = false;
  };
}
