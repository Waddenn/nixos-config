{ config, pkgs, ... }:
{
  hardware.bluetooth.enable = true;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;

    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.pulseaudio.enable = false;

  services.printing.enable = true;

  # services.printing.drivers = [ pkgs.hplip ];

}
