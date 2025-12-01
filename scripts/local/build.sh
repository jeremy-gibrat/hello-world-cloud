#!/bin/bash

# Script de build pour environnement local (Minikube)

set -euo pipefail

# Charger les bibliothèques
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/docker.sh"

cd "$PROJECT_ROOT"

separator
log_step "Build des images Docker pour Minikube"
separator

# Vérifier les prérequis
check_prerequisites docker minikube || exit 1

# Vérifier que Docker et Minikube sont démarrés
check_docker_running || exit 1

if ! minikube status &>/dev/null; then
    log_error "Minikube n'est pas démarré"
    log_info "Lancez Minikube avec: minikube start"
    exit 1
fi

# Construire et charger les images
build_local_images \
    "$PROJECT_ROOT/apps/backend" \
    "$PROJECT_ROOT/apps/frontend" \
    "hello-backend" \
    "hello-frontend"

separator
log_success "Build terminé avec succès!"
log_info "Prochaine étape: make deploy-local"
separator
