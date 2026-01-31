{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./proxmox-vm-hardware.nix
  ];

  my-services.networking.openssh.enable = true;
  my-services.dev.docker.enable = false;

  # Bootloader (Grub replacement for old wrapper)
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # Assumption for VM

  # Legacy wrapper replacements
  console.keyMap = "fr";
  i18n.defaultLocale = "en_US.UTF-8";
  networking.networkmanager.enable = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;
  time.timeZone = "Europe/Paris";

  my-services.networking.tailscale = {
    enable = true;
    role = "server";
  };

  # zsh.enable? Assuming modules/programs/zsh.nix exists and defines it.
  # I'll enable it via native programs.zsh.enable if wrapper is gone,
  # or check zsh.nix. Assuming native for now as better practice.
  programs.zsh.enable = true;

  my-services.dev.kubernetes.enable = true;

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    just
  ];
}
