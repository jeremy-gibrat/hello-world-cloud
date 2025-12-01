#!/bin/bash

# Script de nettoyage pour environnement local (Minikube)

set -euo pipefail

# Charger les bibliothèques
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/k8s.sh"

cd "$PROJECT_ROOT"

RELEASE_NAME="hello-world"

separator
log_step "Nettoyage de l'environnement Minikube"
separator

# Vérifier les prérequis
check_prerequisites kubectl helm || exit 1

# Vérifier qu'on est sur Minikube
ensure_minikube_context || exit 1

# Nettoyer les ressources Helm
helm_cleanup "$RELEASE_NAME"

separator
log_success "Nettoyage terminé!"
log_info "Pour arrêter Minikube: minikube stop"
separator
