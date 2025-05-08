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
    inputs.alejandra.defaultPackage.x86_64-linux
    swayosd
    vscode
    obsidian
    discord
    nextcloud-client
    miru
    # xdg-desktop-portal
    # xdg-desktop-portal-hyprland
    plex-desktop
    xdg-utils
    plexamp
    blanket
    papers
    whatip
    youtube-music
    fastfetch
    grim
    slurp
    swappy
    wl-clipboard
    # qt5.qtwayland
    # qt6.qtwayland
    # libsForQt5.qt5ct
    # qt6ct
    # wayland-utils
    # wayland-protocols
    pamixer
    brightnessctl
    playerctl
    resources
    planify
    peaclock
    cbonsai
    pipes
    cmatrix
    hyprshot
    hyprpicker
    imv
    wf-recorder
    wlr-randr
    # gnome-themes-extra
    libva
    dconf
    glib
    direnv
    meson
    trayscale
    showtime
    libreoffice
    nautilus
  ];

  # xdg.portal = {
  #   enable = true;
  #   xdgOpenUsePortal = true;
  #   config = {
  #     common.default = ["gtk"];
  #     hyprland.default = ["gtk" "hyprland"];
  #   };

  #   extraPortals = [pkgs.xdg-desktop-portal-gtk];
  # };

  # environment.variables = {
  #   XDG_DATA_HOME = "$HOME/.local/share";
  #   PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
  #   EDITOR = "nano";
  #   TERMINAL = "kitty";
  #   TERM = "kitty";
  #   BROWSER = "firefox";
  # };

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
  upower.enable = true;
  blueman.enable = true;
  hardware.amd.enable = true;
  virtualisation.libvirtd.enable = false;
  services.power-profiles-daemon.enable = true;

  # home-manager.users.tom = ./home/tom/home.nix;
  home-manager.users.wade = import ./home.nix;
}
