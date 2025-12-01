#!/bin/bash

# Script pour builder et pousser les images Docker vers GitHub Container Registry

set -e

echo "🐳 Build et push des images Docker vers GHCR"
echo ""

# Vérifier les prérequis
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé"
    exit 1
fi

# Vérifier que Docker est démarré
if ! docker info &> /dev/null; then
    echo "❌ Docker n'est pas démarré. Lancez Docker Desktop."
    exit 1
fi

# Demander le username GitHub si non fourni
if [ -z "$GITHUB_USERNAME" ]; then
    read -p "Entrez votre username GitHub: " GITHUB_USERNAME
fi

# Demander le token GitHub si non fourni
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Entrez votre GitHub Personal Access Token (PAT) avec les scopes 'write:packages' et 'read:packages':"
    read -s GITHUB_TOKEN
    echo ""
fi

# Connexion à GHCR
echo "🔐 Connexion à GitHub Container Registry..."
echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin

if [ $? -ne 0 ]; then
    echo "❌ Échec de la connexion à GHCR"
    exit 1
fi

echo "✅ Connecté à GHCR"
echo ""

# Variables
GHCR_REPO="ghcr.io/$GITHUB_USERNAME"
BACKEND_IMAGE="$GHCR_REPO/hello-backend"
FRONTEND_IMAGE="$GHCR_REPO/hello-frontend"
TAG="latest"

# Build Backend
echo "🔨 Build de l'image backend..."
cd backend
docker build -t "$BACKEND_IMAGE:$TAG" .

if [ $? -ne 0 ]; then
    echo "❌ Échec du build backend"
    exit 1
fi

echo "✅ Image backend buildée: $BACKEND_IMAGE:$TAG"
echo ""

# Build Frontend
echo "🔨 Build de l'image frontend..."
cd ../frontend
docker build -t "$FRONTEND_IMAGE:$TAG" .

if [ $? -ne 0 ]; then
    echo "❌ Échec du build frontend"
    exit 1
fi

echo "✅ Image frontend buildée: $FRONTEND_IMAGE:$TAG"
echo ""
cd ..

# Push des images
echo "📤 Push de l'image backend vers GHCR..."
docker push "$BACKEND_IMAGE:$TAG"

if [ $? -ne 0 ]; then
    echo "❌ Échec du push backend"
    exit 1
fi

echo "✅ Backend poussé sur GHCR"
echo ""

echo "📤 Push de l'image frontend vers GHCR..."
docker push "$FRONTEND_IMAGE:$TAG"

if [ $? -ne 0 ]; then
    echo "❌ Échec du push frontend"
    exit 1
fi

echo "✅ Frontend poussé sur GHCR"
echo ""

# Résumé
echo "🎉 Images Docker buildées et poussées avec succès!"
echo ""
echo "📦 Images disponibles sur:"
echo "   Backend:  $BACKEND_IMAGE:$TAG"
echo "   Frontend: $FRONTEND_IMAGE:$TAG"
echo ""
echo "💡 Prochaines étapes:"
echo "   1. Vérifiez que helm/values-azure.yaml utilise les bonnes images"
echo "   2. Exécutez: ./azure-deploy.sh"
echo ""

# Optionnel: mettre à jour automatiquement values-azure.yaml
read -p "Voulez-vous mettre à jour automatiquement helm/values-azure.yaml ? (yes/no): " update_values

if [ "$update_values" = "yes" ]; then
    echo "📝 Mise à jour de helm/values-azure.yaml..."
    
    # Backup
    cp helm/values-azure.yaml helm/values-azure.yaml.bak
    
    # Remplacement des valeurs
    sed -i '' "s|repository: ghcr.io/.*/hello-backend|repository: $BACKEND_IMAGE|g" helm/values-azure.yaml
    sed -i '' "s|repository: ghcr.io/.*/hello-frontend|repository: $FRONTEND_IMAGE|g" helm/values-azure.yaml
    
    echo "✅ helm/values-azure.yaml mis à jour"
    echo "   (backup sauvegardé dans helm/values-azure.yaml.bak)"
fi
