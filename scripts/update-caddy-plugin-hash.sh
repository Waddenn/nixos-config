#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
hash_file="$repo_root/modules/services/networking/caddy-plugin-hash.txt"
caddy_package="path:$repo_root#nixosConfigurations.caddy.config.services.caddy.package"
build_log="$(mktemp)"
old_hash="$(mktemp)"

cleanup() {
  rm -f "$build_log" "$old_hash"
}
trap cleanup EXIT

cp "$hash_file" "$old_hash"

if nix build "$caddy_package" --no-link >"$build_log" 2>&1; then
  echo "Caddy plugin hash is already valid."
  exit 0
fi

if ! grep -q "caddy-src-with-plugins" "$build_log" ||
  ! grep -q "hash mismatch in fixed-output derivation" "$build_log"; then
  cat "$build_log" >&2
  echo "Caddy build failed for a reason other than the plugin source hash." >&2
  exit 1
fi

new_hash="$(
  sed -nE 's/.*got:[[:space:]]+(sha256-[A-Za-z0-9+\/=]+).*/\1/p' "$build_log" |
    tail -n 1
)"

if [[ -z "$new_hash" ]]; then
  cat "$build_log" >&2
  echo "Could not extract the Caddy plugin source hash from the Nix error." >&2
  exit 1
fi

printf '%s\n' "$new_hash" >"$hash_file"

if ! nix build "$caddy_package" --no-link; then
  cp "$old_hash" "$hash_file"
  echo "The new Caddy plugin hash did not produce a valid package; restored the previous hash." >&2
  exit 1
fi

echo "Updated Caddy plugin hash to $new_hash."
