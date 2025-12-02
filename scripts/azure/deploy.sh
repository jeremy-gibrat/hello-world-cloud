#!/bin/bash

# Script de déploiement pour environnement Azure (AKS)

set -euo pipefail

# Charger les bibliothèques
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_SCRIPT="$SCRIPT_DIR/build.sh"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/k8s.sh"

cd "$PROJECT_ROOT"

RELEASE_NAME="hello-world"

separator
log_step "Déploiement sur Azure AKS"
separator

# Vérifier les prérequis
check_prerequisites terraform az kubectl helm || exit 1

# Charger la configuration
load_env || exit 1

# Vérifier la connexion Azure
log_step "Vérification de la connexion Azure..."
if ! az account show &> /dev/null; then
    log_error "Vous n'êtes pas connecté à Azure"
    log_info "Connectez-vous avec: az login"
    exit 1
fi

AZURE_SUBSCRIPTION=$(az account show --query name -o tsv)
log_success "Connecté à Azure (subscription: $AZURE_SUBSCRIPTION)"

# Option pour builder et pousser les images
if confirm "Voulez-vous builder et pousser les images Docker avant le déploiement ?" "no"; then
    separator
    "$BUILD_SCRIPT" || exit 1
    separator
fi

# Terraform - Vérifier/Créer l'infrastructure
cd "$PROJECT_ROOT/terraform"

if [ ! -f terraform.tfvars ]; then
    log_step "Génération de terraform.tfvars depuis .env..."
    chmod +x generate-tfvars.sh
    ./generate-tfvars.sh
fi

log_step "Initialisation de Terraform..."
terraform init

log_step "Planification de l'infrastructure..."
terraform plan

if confirm "Voulez-vous appliquer ces changements ?" "yes"; then
    log_step "Création de l'infrastructure Azure..."
    terraform apply -auto-approve
else
    log_error "Déploiement annulé"
    exit 0
fi

# Récupérer les credentials AKS
log_step "Récupération des credentials kubectl..."
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
CLUSTER_NAME=$(terraform output -raw cluster_name)

cd "$PROJECT_ROOT"

# Configurer le contexte AKS
ensure_aks_context "$CLUSTER_NAME" || exit 1

# Vérifier que le cluster est accessible
log_step "Vérification du cluster..."
kubectl cluster-info
kubectl get nodes

# Déterminer le namespace depuis values-azure.yaml
NAMESPACE=$(awk '/^namespace:/,/^  name:/ {if (/^  name:/) print $2}' "$PROJECT_ROOT/helm/values-azure.yaml")
log_debug "Namespace: $NAMESPACE"

# Déployer avec Helm d'abord pour créer le namespace
separator
log_step "Déploiement de l'application avec Helm..."

if ! grep -q "your-github-username" "$PROJECT_ROOT/helm/values-azure.yaml" 2>/dev/null; then
    log_warning "Assurez-vous d'avoir modifié les image repositories dans helm/values-azure.yaml"
    if ! confirm "Voulez-vous continuer ?" "yes"; then
        log_error "Déploiement annulé"
        log_info "Modifiez helm/values-azure.yaml avant de continuer"
        exit 0
    fi
fi

helm_deploy "$RELEASE_NAME" "$PROJECT_ROOT/helm" "-f $PROJECT_ROOT/helm/values-azure.yaml" "$NAMESPACE"

# Créer les secrets Kubernetes après que le namespace existe
create_k8s_secrets "$NAMESPACE" || exit 1

# Attendre que les pods soient prêts
wait_for_pods "app=hello-world-backend" 10 "$NAMESPACE" || true
wait_for_pods "app=hello-world-frontend" 10 "$NAMESPACE" || true

separator
log_success "Application déployée avec succès sur Azure AKS!"
separator

# Afficher l'état
show_cluster_status

separator
log_info "Pour accéder au frontend, utilisez:"
log_info "  make tunnel"
log_info ""
log_info "Ou récupérez l'IP externe du LoadBalancer:"
log_info "  kubectl get service hello-world-frontend-service --watch"
separator
