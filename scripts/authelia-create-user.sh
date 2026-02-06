#!/usr/bin/env bash
# Script pour créer un utilisateur Authelia
# Usage: ./scripts/authelia-create-user.sh [username] [displayname] [email] [groups]

set -euo pipefail

USERNAME="${1:-}"
DISPLAYNAME="${2:-}"
EMAIL="${3:-}"
GROUPS="${4:-users}"

USERS_FILE="/var/lib/authelia/users_database.yml"

# Vérifier si authelia est disponible
if ! command -v authelia &> /dev/null; then
    echo "❌ Authelia n'est pas installé."
    echo ""
    echo "Installez-le avec: nix-shell -p authelia"
    exit 1
fi

# Mode interactif si pas d'arguments
if [ -z "$USERNAME" ]; then
    echo "🔐 Création d'un utilisateur Authelia"
    echo ""
    read -p "Nom d'utilisateur: " USERNAME
    read -p "Nom d'affichage: " DISPLAYNAME
    read -p "Email: " EMAIL
    read -p "Groupes (séparés par des virgules, défaut: users): " GROUPS_INPUT
    GROUPS="${GROUPS_INPUT:-users}"
fi

# Demander le mot de passe
echo ""
read -sp "Mot de passe pour $USERNAME: " password
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

# Générer le hash
hash=$(authelia crypto hash generate argon2 --password "$password" 2>/dev/null | grep -oP '(?<=Digest: ).*')

# Convertir les groupes en format YAML
IFS=',' read -ra GROUP_ARRAY <<< "$GROUPS"
GROUPS_YAML=""
for group in "${GROUP_ARRAY[@]}"; do
    group=$(echo "$group" | xargs) # trim whitespace
    GROUPS_YAML="${GROUPS_YAML}      - ${group}\n"
done

echo ""
echo "✅ Utilisateur créé avec succès!"
echo ""
echo "📋 Configuration à ajouter dans users_database.yml:"
echo ""
cat << EOF
  $USERNAME:
    displayname: "$DISPLAYNAME"
    password: "$hash"
    email: $EMAIL
    groups:
$(echo -e "$GROUPS_YAML")
EOF
echo ""
echo "📝 Instructions de déploiement:"
echo ""
echo "1. SSH sur le serveur authelia:"
echo "   ssh root@authelia"
echo ""
echo "2. Éditez le fichier utilisateurs:"
echo "   nano $USERS_FILE"
echo ""
echo "3. Ajoutez la configuration ci-dessus sous la section 'users:'"
echo ""
echo "4. Le fichier sera rechargé automatiquement (watch: true)"
echo "   Ou redémarrez manuellement: systemctl reload authelia"
echo ""
