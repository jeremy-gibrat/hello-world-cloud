#!/bin/bash

# Script de nettoyage pour environnement Azure (AKS)

set -euo pipefail

# Charger les bibliothèques
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/k8s.sh"

cd "$PROJECT_ROOT"

RELEASE_NAME="hello-world"

separator
log_step "Nettoyage de l'environnement Azure AKS"
separator

# Vérifier les prérequis
check_prerequisites terraform kubectl helm || exit 1

# Charger la configuration
load_env || exit 1

# Nettoyer les ressources Kubernetes
log_step "Suppression des ressources Kubernetes..."
helm_cleanup "$RELEASE_NAME"

# Option pour détruire l'infrastructure Terraform
if confirm "Voulez-vous également détruire l'infrastructure Azure (cluster AKS) ?" "no"; then
    cd "$PROJECT_ROOT/terraform"
    
    log_warning "⚠️  Cette action va détruire toute l'infrastructure Azure!"
    if confirm "Êtes-vous sûr ?" "no"; then
        log_step "Destruction de l'infrastructure Terraform..."
        terraform destroy -auto-approve
        log_success "Infrastructure Azure détruite"
    else
        log_info "Destruction annulée"
    fi
fi

separator
log_success "Nettoyage terminé!"
separator
