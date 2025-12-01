#!/bin/bash

# Script pour builder et pousser les images Docker vers GitHub Container Registry

set -e

echo "🐳 Build et push des images Docker vers GHCR"
echo ""

# Charger les variables d'environnement depuis .env
if [ -f .env ]; then
    echo "📝 Chargement de la configuration depuis .env"
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "⚠️  Fichier .env non trouvé. Copiez .env.example vers .env et configurez-le."
    exit 1
fi

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

# Utiliser les variables du .env
GITHUB_USERNAME="$GHCR_USERNAME"
GITHUB_TOKEN="$GHCR_TOKEN"

# Vérifier que les variables sont définies
if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ GHCR_USERNAME ou GHCR_TOKEN non défini dans .env"
    exit 1
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

# Vérifier et créer le builder buildx si nécessaire
echo "🔧 Configuration de Docker buildx..."
if ! docker buildx ls | grep -q "multiplatform"; then
    docker buildx create --name multiplatform --use
    docker buildx inspect --bootstrap
else
    docker buildx use multiplatform
fi
echo ""

# Build Backend (multi-platform pour supporter ARM et AMD64)
echo "🔨 Build de l'image backend (multi-platform: linux/amd64,linux/arm64)..."
cd backend
docker buildx build --platform linux/amd64,linux/arm64 -t "$BACKEND_IMAGE:$TAG" --push .

if [ $? -ne 0 ]; then
    echo "❌ Échec du build backend"
    exit 1
fi

echo "✅ Image backend buildée et poussée: $BACKEND_IMAGE:$TAG"
echo ""

# Build Frontend (multi-platform pour supporter ARM et AMD64)
echo "🔨 Build de l'image frontend (multi-platform: linux/amd64,linux/arm64)..."
cd ../frontend
docker buildx build --platform linux/amd64,linux/arm64 -t "$FRONTEND_IMAGE:$TAG" --push .

if [ $? -ne 0 ]; then
    echo "❌ Échec du build frontend"
    exit 1
fi

echo "✅ Frontend buildée et poussée: $FRONTEND_IMAGE:$TAG"
echo ""
cd ..

# Résumé
echo "🎉 Images Docker buildées et poussées avec succès (multi-platform)!"
echo ""
echo "📦 Images disponibles sur:"
echo "   Backend:  $BACKEND_IMAGE:$TAG (linux/amd64, linux/arm64)"
echo "   Frontend: $FRONTEND_IMAGE:$TAG (linux/amd64, linux/arm64)"
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
