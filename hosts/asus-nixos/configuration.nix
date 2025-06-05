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
    ../../modules/audio.nix
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
    inputs.plex-client.packages.${system}.plex-minimal
    swayosd
    vscode
    obsidian
    discord
    youtube-music
    fastfetch
    grim
    slurp
    pamixer
    playerctl
    resources
    libreoffice
    trayscale
    gnome-text-editor
    mpv
    microfetch
    chromium
    cmatrix
    cbonsai
    yazi
    nextcloud-client
    sshfs
  ];

  services.flatpak.packages = [
    "org.fedoraproject.MediaWriter"
    "com.github.taiko2k.avvie"
    "com.github.tchx84.Flatseal"
    "io.github.alainm23.planify"
  ];

  firefox.enable = true;
  bluetooth.enable = true;
  systemd-boot.enable = true;
  i18n.enable = true;
  tailscale-client.enable = true;
  allowUnfree.enable = false;
  direnv.enable = true;
  steam.enable = true;
  fish.enable = true;
  timeZone.enable = true;
  gnome-excludePackages.enable = false;
  gnomeExtensions.enable = false;
  flatpak.enable = true;
  printing.enable = true;
  pipewire.enable = true;
  fprintd.enable = false;
  fwupd.enable = true;
  gnome.enable = false;
  gdm.enable = false;
  docker.enable = false;
  hyprland.enable = true;
  linuxPackages.enableLatest = true;
  blueman.enable = true;
  hardware.amd.enable = true;
  programs.chromium.enable = true;
  programs.gnome-disks.enable = true;
  programs.kdeconnect.enable = true;
  # environment.sessionVariables.NIXOS_OZONE_WL = "1";
  home-manager.users.tom = import ./home.nix;
}
