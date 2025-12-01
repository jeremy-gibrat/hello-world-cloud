#!/bin/bash

# Script utilitaire pour créer les secrets Kubernetes

set -euo pipefail

# Charger les bibliothèques
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/k8s.sh"

cd "$PROJECT_ROOT"

separator
log_step "Création des secrets Kubernetes depuis .env"
separator

# Charger la configuration
load_env || exit 1

# Créer les secrets
create_k8s_secrets || exit 1

separator
log_success "Secrets créés avec succès!"
log_info "Les secrets ne sont PAS stockés dans values.yaml"
separator
