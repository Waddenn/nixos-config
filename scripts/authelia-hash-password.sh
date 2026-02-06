#!/usr/bin/env bash
# Script pour générer un hash Authelia compatible argon2id
# Usage: ./authelia-hash-password.sh

set -euo pipefail

# Vérifier si authelia est disponible
if ! command -v authelia &> /dev/null; then
    echo "❌ Authelia n'est pas installé."
    echo ""
    echo "Options pour installer:"
    echo "  1. Temporairement: nix-shell -p authelia"
    echo "  2. Dans le système:  nix profile install nixpkgs#authelia"
    echo "  3. Avec Docker:      docker run --rm authelia/authelia:latest authelia crypto hash generate argon2"
    exit 1
fi

echo "🔐 Générateur de hash Authelia (Argon2id)"
echo ""

# Demander le mot de passe
read -sp "Entrez le mot de passe: " password
echo ""
read -sp "Confirmez le mot de passe: " password_confirm
echo ""

if [ "$password" != "$password_confirm" ]; then
    echo "❌ Les mots de passe ne correspondent pas!"
    exit 1
fi

if [ ${#password} -lt 8 ]; then
    echo "⚠️  Avertissement: mot de passe très court (moins de 8 caractères)"
fi

echo ""
echo "🔨 Génération du hash..."
echo ""

# Générer le hash
hash=$(authelia crypto hash generate argon2 --password "$password" 2>/dev/null | grep -oP '(?<=Digest: ).*')

echo "✅ Hash généré avec succès!"
echo ""
echo "📋 Copiez cette ligne dans votre users_database.yml:"
echo ""
echo "    password: \"$hash\""
echo ""
echo "Exemple complet:"
echo ""
cat << EOF
users:
  votre_username:
    displayname: "Votre Nom"
    password: "$hash"
    email: votre@email.com
    groups:
      - admins
EOF
echo ""
