#!/usr/bin/env bash
set -Eeuo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export REPO_DIR
if ! command -v nix >/dev/null 2>&1 && command -v distrobox >/dev/null 2>&1; then
  exec distrobox enter nix-deploy -- bash -lc "cd $(printf '%q' "$REPO_DIR") && ./scripts/fleet-status.sh"
fi
exec python3 "$(dirname "${BASH_SOURCE[0]}")/fleet.py" --status
