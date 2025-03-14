
{ config, pkgs, inputs, sops-nix, ... }:

{
  
  imports = [
    ../../modules/global.nix
  ];
  
  environment.systemPackages = with pkgs; [
    age
    sops
    just
  ];

  services.flatpak.packages = [
    "tv.plex.PlexDesktop"
    "org.fedoraproject.MediaWriter"
    "dev.vencord.Vesktop"
    "com.github.taiko2k.avvie"
    "com.boxy_svg.BoxySVG"
    "app.zen_browser.zen"

  ];

  firewall.enable = true;
  autoUpgrade.enable = true;
  firefox.enable = false;
  bluetooth.enable = true;
  systemd-boot.enable = true;
  keyMap.enable = true;
  i18n.enable = true;
  networkmanager.enable = true;
  tailscale-client.enable = true;
  gc.enable = true;
  experimental-features.enable = true;
  allowUnfree.enable = true;
  direnv.enable = true;
  steam.enable = true;
  zsh.enable = true;
  rtkit.enable = true;
  timeZone.enable = true;
  zram.enable = true;
  gnome-excludePackages.enable = true;
  gnomeExtensions.enable = true;
  flatpak.enable = true;
  printing.enable = true;
  pipewire.enable = true;
  fprintd.enable = false;
  fwupd.enable = true;
  xkb.enable = true;
  gnome.enable = true;
  gdm.enable = true;
  docker.enable = false;
  linuxPackages.enableZen = true;   


  services.xserver.videoDrivers = [ "amdgpu" ];

  boot.kernelParams = [
  "amd_pstate_epp=active"
  "amdgpu.sg_display=0"
  "amd_iommu=off"
  "amdgpu.abmlevel=0"
  ];

} 
