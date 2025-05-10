{
  pkgs,
  config,
  inputs,
  ...
}: {
  systemd.services.NetworkManager-wait-online.enable = false;

  services = {
    xserver = {
      enable = true;
      xkb.layout = "fr";
      xkb.variant = "";
    };
    gnome.gnome-keyring.enable = true;
    psd = {
      enable = true;
      resyncTimer = "10m";
    };
  };
  console.keyMap = "fr";

  environment.variables = {
    XDG_DATA_HOME = "$HOME/.local/share";
    PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
    EDITOR = "nvim";
    TERMINAL = "kitty";
    TERM = "kitty";
    BROWSER = "firefox";
  };

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

  # Faster rebuilding
  documentation = {
    enable = true;
    doc.enable = false;
    man.enable = true;
    dev.enable = false;
    info.enable = false;
    nixos.enable = false;
  };

  environment.systemPackages = with pkgs; [
    hyprland-qtutils
    fd
    bc
    gcc
    git-ignore
    xdg-utils
    wget
    curl
    vim
  ];

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config = {
      common.default = ["gtk"];
      hyprland.default = ["gtk" "hyprland"];
    };

    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

  security = {
    # allow wayland lockers to unlock the screen
    pam.services.hyprlock.text = "auth include login";

    # userland niceness
    rtkit.enable = true;

    # don't ask for password for wheel group
    sudo.wheelNeedsPassword = false;
  };

  services.logind.extraConfig = ''
    # don’t shutdown when power button is short-pressed
    HandlePowerKey=ignore
  '';
}
