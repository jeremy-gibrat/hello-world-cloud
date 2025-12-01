#!/bin/bash

# Script pour afficher le statut de l'application

echo "📊 État des pods:"
kubectl get pods -l app=hello-world-backend -o wide
kubectl get pods -l app=hello-world-frontend -o wide
kubectl get pods -l app=rabbitmq -o wide

echo ""
echo "🌐 Services:"
kubectl get services | grep -E "hello|rabbitmq"

echo ""
echo "📝 Logs du backend (dernières 20 lignes):"
kubectl logs -l app=hello-world-backend --tail=20

echo ""
echo "📝 Logs du frontend (dernières 20 lignes):"
kubectl logs -l app=hello-world-frontend --tail=20

echo ""
echo "🐰 Logs RabbitMQ (dernières 20 lignes):"
kubectl logs -l app=rabbitmq --tail=20
