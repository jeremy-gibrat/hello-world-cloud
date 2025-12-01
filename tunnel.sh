#!/bin/bash

# Script pour créer des tunnels kubectl port-forward vers les services Azure AKS
# Permet d'accéder aux services sans LoadBalancer (économie ~36€/mois)

set -e

# Charger les variables d'environnement depuis .env si disponible
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

echo "🚇 Création des tunnels vers les services AKS..."
echo ""
echo "📍 Services accessibles:"
echo "   - Frontend:        http://localhost:8080"
echo "   - Backend API:     http://localhost:8081"
echo "   - RabbitMQ Admin:  http://localhost:15672 (guest/guest)"
echo "   - Kibana:          http://localhost:5601"
echo ""
echo "⚠️  Appuyez sur Ctrl+C pour arrêter tous les tunnels"
echo ""

# Vérifier le contexte Kubernetes
CURRENT_CONTEXT=$(kubectl config current-context)
echo "📌 Contexte actuel: $CURRENT_CONTEXT"
echo ""

# Attendre que les pods soient prêts
echo "⏳ Vérification de l'état des pods..."
kubectl wait --for=condition=ready pod -l app=hello-world-frontend --timeout=120s 2>/dev/null || echo "⚠️  Frontend pas encore prêt"
kubectl wait --for=condition=ready pod -l app=hello-world-backend --timeout=120s 2>/dev/null || echo "⚠️  Backend pas encore prêt"
kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=120s 2>/dev/null || echo "⚠️  RabbitMQ pas encore prêt"
kubectl wait --for=condition=ready pod -l app=kibana --timeout=120s 2>/dev/null || echo "⚠️  Kibana pas encore prêt (peut prendre 2-3 minutes)"

echo ""
echo "⏳ Attente supplémentaire pour Kibana (30 secondes)..."
sleep 30

echo ""
echo "🚀 Démarrage des tunnels..."
echo ""

# Fonction pour nettoyer les processus en arrière-plan à la sortie
cleanup() {
    echo ""
    echo "🛑 Arrêt des tunnels..."
    jobs -p | xargs kill 2>/dev/null || true
    exit 0
}

trap cleanup SIGINT SIGTERM

# Créer les tunnels en arrière-plan
kubectl port-forward service/hello-world-frontend-service 8080:80 &
PID_FRONTEND=$!
echo "✅ Frontend tunnel créé (PID: $PID_FRONTEND)"

kubectl port-forward service/hello-backend-service 8081:8080 &
PID_BACKEND=$!
echo "✅ Backend tunnel créé (PID: $PID_BACKEND)"

kubectl port-forward service/rabbitmq-service 15672:15672 &
PID_RABBITMQ=$!
echo "✅ RabbitMQ Admin tunnel créé (PID: $PID_RABBITMQ)"

kubectl port-forward service/kibana-service 5601:5601 &
PID_KIBANA=$!
echo "✅ Kibana tunnel créé (PID: $PID_KIBANA)"

echo ""
echo "✨ Tous les tunnels sont actifs !"
echo ""
echo "🌐 Ouvrez votre navigateur:"
echo "   - Application: http://localhost:8080"
echo "   - RabbitMQ:    http://localhost:15672"
echo "   - Kibana:      http://localhost:5601"
echo ""
echo "💡 Appuyez sur Ctrl+C pour arrêter"
echo ""

# Attendre indéfiniment (les tunnels tournent en arrière-plan)
wait
