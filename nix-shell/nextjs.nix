{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  name = "nixos-dashboard-dev";

  buildInputs = [
    pkgs.nodejs_20
    pkgs.pnpm
    pkgs.git
    pkgs.nix
    pkgs.sudo
  ];

  shellHook = ''
    echo "✅ Next.js + NixOS development environment ready!"
    echo "📦 Use 'pnpm dev' to start Next.js"
  '';
}
