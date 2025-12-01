#!/bin/bash

# Script pour déployer l'application sur Minikube avec Helm

set -e

RELEASE_NAME="hello-world"

echo "🚀 Déploiement de l'application avec Helm..."

# Vérifier si le release existe déjà
if helm list | grep -q "$RELEASE_NAME"; then
    echo "📦 Mise à jour du release existant..."
    helm upgrade $RELEASE_NAME ./helm
else
    echo "📦 Installation du nouveau release..."
    helm install $RELEASE_NAME ./helm
fi

echo ""
echo "⏳ Attente du démarrage des pods..."
kubectl wait --for=condition=ready pod -l app=hello-world-backend --timeout=120s
kubectl wait --for=condition=ready pod -l app=hello-world-frontend --timeout=120s

echo ""
echo "✅ Application déployée avec succès!"
echo ""
echo "📊 État des pods:"
kubectl get pods

echo ""
echo "🌐 Services:"
kubectl get services

echo ""
echo "🎯 Pour accéder au frontend:"
echo "   minikube service hello-world-frontend-service"
echo ""
echo "Ou utilisez:"
echo "   kubectl port-forward service/hello-world-frontend-service 8081:80"
echo "   Puis ouvrez: http://localhost:8081"
