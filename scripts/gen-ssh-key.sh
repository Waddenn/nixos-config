#!/usr/bin/env bash

set -e

KEY_PATH="$HOME/.ssh/id_ed25519"

if [ -f "$KEY_PATH" ]; then
  echo "La clé SSH $KEY_PATH existe déjà."
else
  echo "Génération d'une nouvelle clé SSH $KEY_PATH..."
  ssh-keygen -t ed25519 -f "$KEY_PATH" -N ""
  echo "Clé SSH générée : $KEY_PATH"
fi
