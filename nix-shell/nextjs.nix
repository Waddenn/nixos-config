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
    echo "✅ Environnement de dev Next.js + NixOS prêt !"
    echo "📦 Utilise 'pnpm dev' pour lancer Next.js"
  '';
}
