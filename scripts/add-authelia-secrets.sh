#!/usr/bin/env bash
# Script pour ajouter facilement les secrets Authelia à SOPS
# Usage: ./scripts/add-authelia-secrets.sh

set -euo pipefail

cd "$(dirname "$0")/.."

echo "🔐 Configuration des secrets Authelia"
echo ""

# Vérifier si le fichier existe déjà
if [ -f "secrets/authelia.env.enc" ]; then
    echo "⚠️  Le fichier secrets/authelia.env.enc existe déjà."
    read -p "Voulez-vous le REMPLACER ? (oui/non): " confirm
    if [ "$confirm" != "oui" ]; then
        echo "❌ Opération annulée."
        exit 0
    fi
    echo ""
fi

echo "🎲 Génération des secrets aléatoires..."

JWT_SECRET=$(openssl rand -base64 32)
STORAGE_KEY=$(openssl rand -base64 32)

# Créer le fichier temporaire non chiffré
TMP_FILE=$(mktemp)
trap "rm -f $TMP_FILE" EXIT

cat > "$TMP_FILE" << EOF
# Authelia Secrets - Généré le $(date)
authelia_jwt_secret=$JWT_SECRET
authelia_storage_encryption_key=$STORAGE_KEY
EOF

echo "✅ Secrets générés :"
echo "   - authelia_jwt_secret"
echo "   - authelia_storage_encryption_key"
echo ""

# Demander si on veut ajouter le mot de passe PostgreSQL
read -p "Utilisez-vous PostgreSQL ? (oui/non, défaut: non): " use_postgres
if [ "${use_postgres:-non}" = "oui" ]; then
    DB_PASSWORD=$(openssl rand -base64 32)
    echo "authelia_db_password=$DB_PASSWORD" >> "$TMP_FILE"
    echo "   - authelia_db_password"
    echo ""
fi

echo "🔒 Chiffrement avec SOPS..."

# Chiffrer avec SOPS
if nix shell nixpkgs#sops --command sops -e "$TMP_FILE" > secrets/authelia.env.enc; then
    echo "✅ Fichier chiffré créé : secrets/authelia.env.enc"
    echo ""

    # Vérifier le résultat
    echo "🔍 Vérification du fichier chiffré..."
    if nix shell nixpkgs#sops --command sops -d secrets/authelia.env.enc > /dev/null 2>&1; then
        echo "✅ Le fichier peut être déchiffré correctement"
        echo ""

        # Afficher le contenu pour vérification
        echo "📋 Contenu (déchiffré) :"
        nix shell nixpkgs#sops --command sops -d secrets/authelia.env.enc
        echo ""

        echo "✅ Configuration terminée !"
        echo ""
        echo "📝 Prochaines étapes :"
        echo "   1. Le module authelia.nix est déjà configuré pour utiliser ces secrets"
        echo "   2. Commitez le fichier chiffré : git add secrets/authelia.env.enc"
        echo "   3. Déployez votre host Authelia"
        echo ""
    else
        echo "❌ Erreur : impossible de déchiffrer le fichier créé"
        exit 1
    fi
else
    echo "❌ Erreur lors du chiffrement"
    exit 1
fi
