{ config, pkgs, ... }:
{
  ############################################
  # PipeWire (audio)
  ############################################
  services.pipewire = {
    enable = true;

    # On active le support ALSA & Pulse
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Désactiver Pulseaudio "classique"
  hardware.pulseaudio.enable = false;

}
