#!/bin/bash

# Script pour vérifier le statut du déploiement Azure

echo "📊 Statut du déploiement Azure AKS"
echo ""

# Vérifier kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl n'est pas installé"
    exit 1
fi

# Vérifier la connexion au cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Impossible de se connecter au cluster Kubernetes"
    echo "Exécutez d'abord: az aks get-credentials --resource-group <rg-name> --name <cluster-name>"
    exit 1
fi

# Afficher le contexte actuel
CURRENT_CONTEXT=$(kubectl config current-context)
echo "📍 Contexte actuel: $CURRENT_CONTEXT"
if [[ "$CURRENT_CONTEXT" == "minikube" ]]; then
    echo "⚠️  Vous êtes sur Minikube, pas sur Azure AKS!"
    echo "   Basculez vers AKS avec: kubectl config use-context aks-hello-world"
    exit 1
fi
echo ""

echo "🎯 Cluster Kubernetes:"
kubectl cluster-info | head -n 1

echo ""
echo "🖥️  Nodes:"
kubectl get nodes -o wide

echo ""
echo "📦 Pods:"
kubectl get pods -o wide

echo ""
echo "🌐 Services:"
kubectl get services

echo ""
echo "📊 Resource Usage:"
kubectl top nodes 2>/dev/null || echo "⚠️  Metrics server non disponible"

echo ""
echo "🌍 URL du Frontend:"
EXTERNAL_IP=$(kubectl get service hello-world-frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" = "null" ]; then
    echo "⏳ En attente de l'IP publique du LoadBalancer..."
    echo "   Réessayez dans quelques minutes ou surveillez avec:"
    echo "   kubectl get service hello-world-frontend-service --watch"
else
    echo "✅ Frontend accessible sur: http://$EXTERNAL_IP"
fi

echo ""
echo "📜 Pour voir les logs:"
echo "   Backend:  kubectl logs -f -l app=hello-world-backend"
echo "   Frontend: kubectl logs -f -l app=hello-world-frontend"
