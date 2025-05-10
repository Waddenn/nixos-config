{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../modules
    ../../modules/fonts.nix
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
    vulkan-tools
    vulkan-loader
    mesa
    inputs.alejandra.defaultPackage.x86_64-linux
    swayosd
    vscode
    obsidian
    discord
    nextcloud-client
    miru
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    # xdg-utils
    plexamp
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
    peaclock
    cbonsai
    pipes
    cmatrix
    showtime
    libreoffice
    nautilus
    distrobox
    boxbuddy
    appimage-run
  ];

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config = {
      common.default = ["gtk"];
      hyprland.default = ["gtk" "hyprland"];
    };

    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  environment.variables = {
    XDG_DATA_HOME = "$HOME/.local/share";
    PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
    EDITOR = "nano";
    TERMINAL = "kitty";
    TERM = "kitty";
    BROWSER = "firefox";
  };

  services.flatpak.packages = [
    "tv.plex.PlexDesktop"
    "org.fedoraproject.MediaWriter"
    "com.github.taiko2k.avvie"
    "com.github.tchx84.Flatseal"
    "com.valvesoftware.Steam"
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
  xkb.enable = true;
  gnome.enable = false;
  gdm.enable = true;
  docker.enable = true;
  hyprland.enable = true;
  linuxPackages.enableTesting = false;
  upower.enable = false;
  blueman.enable = true;
  hardware.amd.enable = true;
  virtualisation.libvirtd.enable = false;
  services.gnome.gnome-keyring.enable = true;
  # home-manager.users.tom = ./home/tom/home.nix;
  home-manager.users.wade = import ./home.nix;

  services.libinput.enable = true;
  programs.dconf.enable = true;
  services = {
    dbus = {
      enable = true;
      implementation = "broker";
      packages = with pkgs; [gcr gnome-settings-daemon];
    };
    gvfs.enable = true;
    upower.enable = true;
    power-profiles-daemon.enable = true;
    udisks2.enable = true;
  };
}
