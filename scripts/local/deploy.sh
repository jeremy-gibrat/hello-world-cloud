#!/bin/bash

# Script de déploiement pour environnement local (Minikube)

set -euo pipefail

# Charger les bibliothèques
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/k8s.sh"

cd "$PROJECT_ROOT"

RELEASE_NAME="hello-world"

separator
log_step "Déploiement sur Minikube"
separator

# Vérifier les prérequis
check_prerequisites kubectl helm || exit 1

# Vérifier qu'on est sur Minikube
ensure_minikube_context || exit 1

# Charger la configuration
load_env || exit 1

# Créer les secrets Kubernetes
create_k8s_secrets || exit 1

# Déployer avec Helm
helm_deploy "$RELEASE_NAME" "$PROJECT_ROOT/helm"

# Attendre que les pods soient prêts
wait_for_pods "app=hello-world-backend" 120
wait_for_pods "app=hello-world-frontend" 120

# Redémarrer les déploiements pour s'assurer d'utiliser les dernières images
log_step "Redémarrage des déploiements pour garantir les dernières images..."
restart_deployments \
    "hello-world-backend" \
    "hello-world-frontend" \
    "rabbitmq"

separator
log_success "Application déployée avec succès sur Minikube!"
separator

# Afficher l'état
show_cluster_status

separator
log_info "Pour accéder au frontend:"
log_info "  minikube service hello-world-frontend-service"
log_info ""
log_info "Ou utilisez:"
log_info "  kubectl port-forward service/hello-world-frontend-service 8081:80"
log_info "  Puis ouvrez: http://localhost:8081"
separator
