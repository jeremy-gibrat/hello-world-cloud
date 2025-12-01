#!/bin/bash

# Script pour construire les images Docker et les charger dans Minikube

set -e

echo "🔨 Construction de l'image Docker du backend (avec --no-cache)..."
cd backend
docker build --no-cache -t hello-backend:latest .
cd ..

echo "🔨 Construction de l'image Docker du frontend (avec --no-cache)..."
cd frontend
docker build --no-cache -t hello-frontend:latest .
cd ..

echo "🗑️  Suppression des anciennes images dans Minikube..."
eval $(minikube docker-env)
docker rmi -f hello-backend:latest hello-frontend:latest 2>/dev/null || true
eval $(minikube docker-env -u)

echo "📦 Chargement des nouvelles images dans Minikube..."
minikube image load hello-backend:latest
minikube image load hello-frontend:latest

echo "✅ Images construites et chargées avec succès!"
echo ""
echo "Images disponibles:"
minikube image ls | grep hello
echo ""
echo "⚠️  Pour appliquer les changements, exécutez:"
echo "   kubectl rollout restart deployment/hello-world-backend deployment/hello-world-frontend"
