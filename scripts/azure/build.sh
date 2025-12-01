#!/bin/bash

# Script de build pour environnement Azure (AKS)

set -euo pipefail

# Charger les bibliothèques
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/docker.sh"

cd "$PROJECT_ROOT"

separator
log_step "Build et push des images Docker vers GHCR"
separator

# Vérifier les prérequis
check_prerequisites docker || exit 1

# Vérifier que Docker est démarré
check_docker_running || exit 1

# Charger la configuration
load_env || exit 1

# Vérifier les variables GHCR
if [ -z "${GHCR_USERNAME:-}" ] || [ -z "${GHCR_TOKEN:-}" ]; then
    log_error "GHCR_USERNAME ou GHCR_TOKEN non défini dans .env"
    exit 1
fi

GHCR_REPO="ghcr.io/$GHCR_USERNAME"

# Construire et pousser les images
build_azure_images \
    "$PROJECT_ROOT/apps/backend" \
    "$PROJECT_ROOT/apps/frontend" \
    "$GHCR_REPO"

separator
log_success "Build et push terminés avec succès!"
log_info "Prochaine étape: make deploy-azure"
separator
