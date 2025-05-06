{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../modules
  ];

  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.age.sshKeyPaths = ["/home/tom/.ssh/id_ed25519"];

  environment.systemPackages = with pkgs; [
    roboto
    work-sans
    comic-neue
    source-sans
    comfortaa
    inter
    lato
    lexend
    jost
    dejavu_fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    nerd-fonts.fira-code
    nerd-fonts.meslo-lg
    openmoji-color
    twemoji-color-font
    age
    sops
    just
    mesa
    brightnessctl
    pamixer
    inputs.alejandra.defaultPackage.x86_64-linux
    trayscale
  ];

  services.flatpak.packages = [
    "tv.plex.PlexDesktop"
    "org.fedoraproject.MediaWriter"
    "com.github.taiko2k.avvie"
    "com.boxy_svg.BoxySVG"
    "com.github.tchx84.Flatseal"
  ];

  autoUpgrade.enable = true;
  autoUpgrade.updateFlakeLock = true;
  firefox.enable = true;
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
  fish.enable = true;
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
  docker.enable = true;
  hyprland.enable = true;
  hardware.cpu.amd.updateMicrocode = true;
  linuxPackages.enableTesting = false;
  virtualisation.libvirtd.enable = true;
  discord.enable = true;
}
