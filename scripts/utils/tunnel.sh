#!/bin/bash

# Script utilitaire pour créer des tunnels SSH vers les services Azure

set -euo pipefail

# Charger les bibliothèques
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/k8s.sh"

separator
log_step "Création des tunnels vers les services"
separator

log_info "Tunnels créés:"
log_info "  Frontend:  http://localhost:8080"
log_info "  Backend:   http://localhost:8081"
log_info "  RabbitMQ:  http://localhost:15672 (guest/guest)"
log_info "  Kibana:    http://localhost:5601"
log_info ""
log_warning "Appuyez sur Ctrl+C pour arrêter les tunnels"

separator

# Créer les tunnels (cette commande bloque)
kubectl port-forward service/hello-world-frontend-service 8080:80 &
kubectl port-forward service/hello-world-backend-service 8081:8080 &
kubectl port-forward service/rabbitmq-service 15672:15672 &
kubectl port-forward service/kibana-service 5601:5601 &

# Attendre l'interruption
wait
