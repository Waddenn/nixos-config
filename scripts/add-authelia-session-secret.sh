#!/usr/bin/env bash
# Script pour ajouter authelia_session_secret dans secrets.yaml
# Usage: ./scripts/add-authelia-session-secret.sh

set -euo pipefail

echo "🔐 Ajout de authelia_session_secret dans secrets.yaml"
echo ""

# Générer un secret aléatoire de 64 caractères
echo "🔨 Génération d'un secret aléatoire..."
SESSION_SECRET=$(openssl rand -hex 32)

echo "✅ Secret généré: ${SESSION_SECRET:0:16}... (tronqué)"
echo ""
echo "📝 Ajoutez cette ligne dans secrets.yaml avec:"
echo "   just secrets-edit"
echo ""
echo "Sous la section authelia:"
echo ""
echo "authelia_session_secret: \"$SESSION_SECRET\""
echo ""
echo "💡 Après l'ajout, relancez le déploiement:"
echo "   just deploy"
echo ""
