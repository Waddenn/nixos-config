
{ ... }:

{
  imports = [

    ./boot/loader/systemd-boot.nix
    ./boot/loader/grub.nix
    ./boot/kernel.nix
    ./hardware/bluetooth.nix
    ./networking/firewall.nix
    ./programs/firefox.nix
    ./system/autoUpgrade.nix
    ./console/keyMap.nix
    ./i18n/i18n.nix
    ./networking/networkmanager.nix
    ./services/tailscale-client.nix
    ./services/tailscale-server.nix
    ./nix/gc.nix
    ./nix/settings.nix
    ./nixpkgs/config.nix
    ./programs/direnv.nix
    ./programs/steam.nix
    ./programs/zsh.nix
    ./programs/terraform.nix
    ./programs/ansible.nix
    ./programs/python3Minimal.nix
    ./security/rtkit.nix
    ./time/timeZone.nix
    ./zramSwap/zramswap.nix
    ./environment/gnome/excludePackages.nix    
    ./environment/systemPackages/gnomeExtensions.nix
    ./environment/systemPackages/ethtool.nix
    ./services/flatpak.nix
    ./services/printing.nix
    ./services/pipewire.nix
    ./services/fwupd.nix
    ./services/fprintd.nix
    ./services/xserver-xkb.nix
    ./services/gnome.nix
    ./services/gdm.nix
    ./services/caddy.nix
    ./hardware/nvidia.nix
    ./services/openssh.nix
    ./services/docker.nix
    ./services/grafana.nix
    ./services/prometheus.nix
    ./services/gotify.nix
    ./services/gitea.nix
    ./services/vaultwarden.nix
    ./services/paperless.nix
    ./services/gitlab.nix
    ./services/immich.nix
  ];

} 