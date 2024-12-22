{ config, pkgs, ... }:
{
  ###############################
  # Impression
  ###############################
  services.printing.enable = true;

  # Ex: configuration CUPS additionnelle
  # services.printing.drivers = [ pkgs.hplip ];
}
