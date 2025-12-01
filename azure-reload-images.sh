#!/bin/bash

# Script pour forcer le rechargement des images Docker sur Azure AKS
# Utilise une stratégie de suppression de pods au lieu de rollout restart
# pour éviter les problèmes de ressources insuffisantes

set -e

echo "🔄 Rechargement des images sur Azure AKS"
echo ""

# Vérifier qu'on est sur le bon contexte
CURRENT_CONTEXT=$(kubectl config current-context)
echo "📍 Contexte kubectl actuel: $CURRENT_CONTEXT"

if [[ ! "$CURRENT_CONTEXT" =~ "aks" ]] && [[ ! "$CURRENT_CONTEXT" =~ "azure" ]]; then
    echo "⚠️  Attention: Ce contexte ne semble pas être Azure AKS"
    read -p "Voulez-vous continuer ? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Annulé"
        exit 0
    fi
fi

echo ""
echo "📦 Services à recharger:"
echo "  1. Backend"
echo "  2. Frontend"
echo "  3. Les deux"
echo ""
read -p "Votre choix (1/2/3): " choice

case $choice in
    1)
        echo "🔄 Rechargement du backend..."
        kubectl delete pod -l app=hello-world-backend
        echo "⏳ Attente du nouveau pod backend..."
        kubectl wait --for=condition=ready pod -l app=hello-world-backend --timeout=120s
        echo "✅ Backend rechargé"
        ;;
    2)
        echo "🔄 Rechargement du frontend..."
        kubectl delete pod -l app=hello-world-frontend
        echo "⏳ Attente du nouveau pod frontend..."
        kubectl wait --for=condition=ready pod -l app=hello-world-frontend --timeout=120s
        echo "✅ Frontend rechargé"
        ;;
    3)
        echo "🔄 Rechargement du backend..."
        kubectl delete pod -l app=hello-world-backend
        echo "⏳ Attente du nouveau pod backend..."
        kubectl wait --for=condition=ready pod -l app=hello-world-backend --timeout=120s
        echo "✅ Backend rechargé"
        
        echo ""
        echo "🔄 Rechargement du frontend..."
        kubectl delete pod -l app=hello-world-frontend
        echo "⏳ Attente du nouveau pod frontend..."
        kubectl wait --for=condition=ready pod -l app=hello-world-frontend --timeout=120s
        echo "✅ Frontend rechargé"
        ;;
    *)
        echo "❌ Choix invalide"
        exit 1
        ;;
esac

echo ""
echo "✅ Rechargement terminé!"
echo ""
echo "📊 État des pods:"
kubectl get pods
echo ""
echo "💡 Astuce: Les nouvelles images sont téléchargées grâce à imagePullPolicy: Always"
