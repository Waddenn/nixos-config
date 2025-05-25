{pkgs, ...}: let
  tailscale-up = pkgs.writeShellScriptBin "tailscale-up" ''
    if ! tailscale status --json | jq -e '.Self.Online == true' > /dev/null; then
      sudo tailscale up
      notif "Tailscale" "Activated" "Tailscale VPN has been activated"
    else
      notif "Tailscale" "Already active" "Tailscale is already connected"
    fi
  '';

  tailscale-down = pkgs.writeShellScriptBin "tailscale-down" ''
    sudo tailscale down
    notif "Tailscale" "Deactivated" "Tailscale VPN has been deactivated"
  '';

  tailscale-toggle = pkgs.writeShellScriptBin "tailscale-toggle" ''
    if tailscale status --json | jq -e '.Self.Online == true' > /dev/null; then
      tailscale-down
    else
      tailscale-up
    fi
  '';
in {
  home.packages = [
    pkgs.tailscale
    pkgs.jq
    tailscale-up
    tailscale-down
    tailscale-toggle
  ];
}
