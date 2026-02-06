#!/usr/bin/env bash
# Script pour initialiser le fichier users_database.yml sur le serveur Authelia
# Usage: ./scripts/authelia-init-users.sh [hostname]

set -euo pipefail

HOST="${1:-authelia}"
REMOTE_FILE="/var/lib/authelia/users_database.yml"

echo "🔐 Initialisation du fichier users_database.yml sur $HOST"
echo ""

# Vérifier que le host est accessible
if ! ssh -q root@"$HOST" exit 2>/dev/null; then
    echo "❌ Impossible de se connecter à root@$HOST"
    echo "Vérifiez que le host est déployé et SSH est configuré."
    exit 1
fi

# Demander les infos de l'admin
echo "Création de l'utilisateur administrateur initial:"
echo ""
read -p "Nom d'utilisateur admin (défaut: admin): " ADMIN_USER
ADMIN_USER="${ADMIN_USER:-admin}"

read -p "Nom d'affichage (défaut: Administrator): " ADMIN_NAME
ADMIN_NAME="${ADMIN_NAME:-Administrator}"

read -p "Email (défaut: admin@hexaflare.net): " ADMIN_EMAIL
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@hexaflare.net}"

echo ""
read -sp "Mot de passe admin: " ADMIN_PASSWORD
echo ""
read -sp "Confirmez le mot de passe: " ADMIN_PASSWORD_CONFIRM
echo ""

if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
    echo "❌ Les mots de passe ne correspondent pas!"
    exit 1
fi

echo ""
echo "🔨 Génération du hash..."

# Vérifier si authelia est disponible localement
if ! command -v authelia &> /dev/null; then
    echo "📦 Installation temporaire d'Authelia..."
    HASH=$(nix shell nixpkgs#authelia --command bash -c "authelia crypto hash generate argon2 --password '$ADMIN_PASSWORD' 2>/dev/null" | grep -oP '(?<=Digest: ).*')
else
    HASH=$(authelia crypto hash generate argon2 --password "$ADMIN_PASSWORD" 2>/dev/null | grep -oP '(?<=Digest: ).*')
fi

echo "✅ Hash généré"
echo ""

# Créer le fichier temporaire
TMP_FILE=$(mktemp)
trap "rm -f $TMP_FILE" EXIT

cat > "$TMP_FILE" << EOF
###############################################################
#                Authelia Users Database                      #
###############################################################
# Ce fichier définit les utilisateurs pour le backend "file"
# Géré par NixOS - Créé le $(date)

users:
  $ADMIN_USER:
    displayname: "$ADMIN_NAME"
    password: "$HASH"
    email: $ADMIN_EMAIL
    groups:
      - admins
      - users

###############################################################
# Pour ajouter des utilisateurs:                              #
###############################################################
# 1. Utilisez: ./scripts/authelia-create-user.sh
# 2. Ou ajoutez manuellement ici et redémarrez
#
# Exemple:
#   john:
#     displayname: "John Doe"
#     password: "\$argon2id\$..."
#     email: john@example.com
#     groups:
#       - users
EOF

echo "📤 Déploiement du fichier sur $HOST..."

# Copier le fichier sur le serveur
scp "$TMP_FILE" "root@$HOST:$REMOTE_FILE"

# Corriger les permissions
ssh "root@$HOST" << REMOTE_COMMANDS
    chown authelia:authelia $REMOTE_FILE
    chmod 600 $REMOTE_FILE
    echo "✅ Fichier déployé et permissions définies"
    echo ""
    echo "📋 Contenu du fichier:"
    cat $REMOTE_FILE
REMOTE_COMMANDS

echo ""
echo "✅ Initialisation terminée!"
echo ""
echo "🔑 Credentials:"
echo "   Username: $ADMIN_USER"
echo "   Email:    $ADMIN_EMAIL"
echo "   Password: <celui que vous avez saisi>"
echo ""
echo "🌐 Vous pouvez maintenant vous connecter à:"
echo "   https://auth.hexaflare.net"
echo ""
