{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../modules
    ../../modules/fonts.nix
    ../../modules/nix.nix
    ../../modules/utils.nix
    ../../modules/sddm.nix
    ../../themes/nixy.nix
    ./variables.nix
  ];

  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.age.sshKeyPaths = ["/home/tom/.ssh/id_ed25519"];

  environment.systemPackages = with pkgs; [
    age
    sops
    just
    inputs.alejandra.defaultPackage.x86_64-linux
    swayosd
    vscode
    obsidian
    discord
    miru
    blanket
    papers
    whatip
    youtube-music
    fastfetch
    grim
    slurp
    pamixer
    playerctl
    resources
    planify
    libreoffice
    nautilus
    bitwarden
    trayscale
    gnome-text-editor
    nextcloud-client
  ];

  services.flatpak.packages = [
    "tv.plex.PlexDesktop"
    "org.fedoraproject.MediaWriter"
    "com.github.taiko2k.avvie"
    "com.github.tchx84.Flatseal"
  ];

  autoUpgrade.enable = true;
  autoUpgrade.updateFlakeLock = true;
  firefox.enable = true;
  bluetooth.enable = true;
  systemd-boot.enable = true;
  keyMap.enable = false;
  i18n.enable = true;
  networkmanager.enable = true;
  tailscale-client.enable = true;
  gc.enable = false;
  experimental-features.enable = false;
  allowUnfree.enable = false;
  direnv.enable = true;
  steam.enable = false;
  zsh.enable = true;
  fish.enable = true;
  rtkit.enable = true;
  timeZone.enable = true;
  zram.enable = true;
  gnome-excludePackages.enable = false;
  gnomeExtensions.enable = false;
  flatpak.enable = true;
  printing.enable = true;
  pipewire.enable = true;
  fprintd.enable = false;
  fwupd.enable = true;
  xkb.enable = false;
  gnome.enable = false;
  gdm.enable = false;
  docker.enable = false;
  hyprland.enable = true;
  linuxPackages.enableLatest = true;
  upower.enable = false;
  blueman.enable = true;
  hardware.amd.enable = true;
  virtualisation.libvirtd.enable = false;
  home-manager.users.tom = import ./home.nix;
}
