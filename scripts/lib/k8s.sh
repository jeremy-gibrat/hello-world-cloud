#!/bin/bash

# Bibliothèque de fonctions Kubernetes

# Charger les fonctions communes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Obtenir le contexte Kubernetes actuel
get_k8s_context() {
    kubectl config current-context 2>/dev/null || echo "unknown"
}

# Vérifier qu'on est sur le bon contexte
check_k8s_context() {
    local expected_context="$1"
    local current_context=$(get_k8s_context)
    
    if [ "$current_context" != "$expected_context" ]; then
        log_warning "Contexte kubectl actuel: $current_context"
        log_warning "Contexte attendu: $expected_context"
        
        if confirm "Voulez-vous basculer vers le contexte $expected_context ?"; then
            kubectl config use-context "$expected_context"
            log_success "Basculé vers le contexte $expected_context"
            return 0
        else
            log_error "Opération annulée"
            return 1
        fi
    fi
    
    log_debug "Contexte kubectl correct: $current_context"
    return 0
}

# Vérifier qu'on est sur Minikube
ensure_minikube_context() {
    check_k8s_context "minikube"
}

# Vérifier qu'on est sur Azure AKS
ensure_aks_context() {
    local cluster_name="$1"
    
    if [ -z "$cluster_name" ]; then
        log_error "Nom du cluster AKS non fourni"
        return 1
    fi
    
    local current_context=$(get_k8s_context)
    
    if [[ "$current_context" != *"$cluster_name"* ]]; then
        log_warning "Contexte kubectl actuel: $current_context"
        log_info "Configuration du contexte AKS..."
        
        local resource_group="${RESOURCE_GROUP_NAME:-}"
        if [ -z "$resource_group" ]; then
            log_error "RESOURCE_GROUP_NAME non défini dans .env"
            return 1
        fi
        
        az aks get-credentials \
            --resource-group "$resource_group" \
            --name "$cluster_name" \
            --overwrite-existing
        
        log_success "Contexte AKS configuré"
    else
        log_debug "Déjà sur le contexte AKS: $current_context"
    fi
    
    return 0
}

# Attendre que les pods soient prêts
wait_for_pods() {
    local label="$1"
    local timeout="${2:-300}"
    local namespace="${3:-}"
    
    local namespace_flag=""
    if [ -n "$namespace" ]; then
        namespace_flag="-n $namespace"
    fi
    
    log_step "Attente du démarrage des pods ($label)..."
    
    if kubectl wait --for=condition=ready pod -l "$label" $namespace_flag --timeout="${timeout}s" 2>/dev/null; then
        log_success "Pods prêts ($label)"
        return 0
    else
        log_warning "Timeout lors de l'attente des pods ($label)"
        log_info "Vérification de l'état des pods..."
        kubectl get pods -l "$label" $namespace_flag
        return 1
    fi
}

# Attendre que le déploiement soit prêt
wait_for_deployment() {
    local deployment="$1"
    local timeout="${2:-300}"
    
    log_step "Attente du déploiement $deployment..."
    
    if kubectl rollout status deployment/"$deployment" --timeout="${timeout}s"; then
        log_success "Déploiement $deployment prêt"
        return 0
    else
        log_error "Échec du déploiement $deployment"
        return 1
    fi
}

# Créer ou mettre à jour les secrets depuis .env
create_k8s_secrets() {
    local namespace="${1:-}"
    
    log_step "Création des secrets Kubernetes depuis .env..."
    
    # Vérifier que les variables sont définies
    if [ -z "${POSTGRES_DB:-}" ] || [ -z "${POSTGRES_USER:-}" ] || [ -z "${POSTGRES_PASSWORD:-}" ]; then
        log_error "Variables PostgreSQL manquantes dans .env"
        log_info "Vérifiez: POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD"
        return 1
    fi
    
    if [ -z "${RABBITMQ_USER:-}" ] || [ -z "${RABBITMQ_PASSWORD:-}" ]; then
        log_error "Variables RabbitMQ manquantes dans .env"
        log_info "Vérifiez: RABBITMQ_USER, RABBITMQ_PASSWORD"
        return 1
    fi
    
    local namespace_flag=""
    if [ -n "$namespace" ]; then
        namespace_flag="-n $namespace"
    fi
    
    # Créer le secret
    kubectl create secret generic app-secrets \
        --from-literal=postgres-db="$POSTGRES_DB" \
        --from-literal=postgres-user="$POSTGRES_USER" \
        --from-literal=postgres-password="$POSTGRES_PASSWORD" \
        --from-literal=rabbitmq-user="$RABBITMQ_USER" \
        --from-literal=rabbitmq-password="$RABBITMQ_PASSWORD" \
        $namespace_flag \
        --dry-run=client -o yaml | kubectl apply $namespace_flag -f -
    
    if [ $? -eq 0 ]; then
        log_success "Secret 'app-secrets' créé/mis à jour"
        return 0
    else
        log_error "Échec de la création du secret"
        return 1
    fi
}

# Déployer avec Helm
helm_deploy() {
    local release_name="$1"
    local chart_path="$2"
    local values_file="${3:-}"
    local namespace="${4:-}"
    
    log_step "Déploiement avec Helm..."
    
    local helm_cmd="helm upgrade --install $release_name $chart_path"
    
    if [ -n "$values_file" ]; then
        helm_cmd="$helm_cmd -f $values_file"
    fi
    
    if [ -n "$namespace" ]; then
        helm_cmd="$helm_cmd -n $namespace --create-namespace"
    fi
    
    log_debug "Commande Helm: $helm_cmd"
    
    if eval "$helm_cmd"; then
        log_success "Application déployée avec Helm"
        return 0
    else
        log_error "Échec du déploiement Helm"
        return 1
    fi
}

# Afficher l'état du cluster
show_cluster_status() {
    separator
    log_info "État du cluster Kubernetes"
    separator
    
    local context=$(get_k8s_context)
    local namespace="default"
    
    # Détecter le namespace selon le contexte
    if [[ "$context" == *"minikube"* ]]; then
        namespace="hello-world-dev"
    elif [[ "$context" == *"aks"* ]] || [[ "$context" != "minikube" ]]; then
        namespace="hello-world-prod"
    fi
    
    echo "📍 Contexte: $context"
    echo "📦 Namespace: $namespace"
    echo ""
    
    echo "🎯 Pods:"
    kubectl get pods -n $namespace
    echo ""
    
    echo "🌐 Services:"
    kubectl get services -n $namespace
    echo ""
    
    echo "📦 Déploiements:"
    kubectl get deployments -n $namespace
    echo ""
}

# Nettoyer les ressources Helm
helm_cleanup() {
    local release_name="$1"
    local namespace="${2:-}"
    
    log_step "Nettoyage du release Helm '$release_name'..."
    
    local namespace_flag=""
    if [ -n "$namespace" ]; then
        namespace_flag="-n $namespace"
    fi
    
    if helm list $namespace_flag | grep -q "$release_name"; then
        helm uninstall "$release_name" $namespace_flag
        log_success "Release '$release_name' supprimé"
    else
        log_info "Release '$release_name' non trouvé"
    fi
    
    # Supprimer les secrets
    if kubectl get secret app-secrets $namespace_flag &>/dev/null; then
        kubectl delete secret app-secrets $namespace_flag
        log_success "Secret 'app-secrets' supprimé"
    fi
}

# Redémarrer les déploiements
restart_deployments() {
    local namespace=""
    local deployments=()
    
    # Si le premier argument contient un slash, c'est un namespace
    if [[ "$1" == *"/"* ]]; then
        namespace="${1%%/*}"
        shift
    fi
    
    deployments=("$@")
    
    log_step "Redémarrage des déploiements..."
    
    local namespace_flag=""
    if [ -n "$namespace" ]; then
        namespace_flag="-n $namespace"
    fi
    
    for deployment in "${deployments[@]}"; do
        if kubectl get deployment "$deployment" $namespace_flag &>/dev/null; then
            kubectl rollout restart deployment/"$deployment" $namespace_flag
            log_info "Déploiement '$deployment' redémarré"
        else
            log_warning "Déploiement '$deployment' non trouvé"
        fi
    done
    
    # Attendre que les redémarrages soient terminés
    for deployment in "${deployments[@]}"; do
        if kubectl get deployment "$deployment" $namespace_flag &>/dev/null; then
            wait_for_deployment "$deployment" 120 $namespace
        fi
    done
}

# Obtenir les logs d'un pod
get_pod_logs() {
    local label="$1"
    local follow="${2:-false}"
    
    log_info "Logs des pods ($label):"
    
    if [ "$follow" = "true" ]; then
        kubectl logs -f -l "$label"
    else
        kubectl logs -l "$label" --tail=100
    fi
}

# Exporter les fonctions
export -f get_k8s_context check_k8s_context ensure_minikube_context ensure_aks_context
export -f wait_for_pods wait_for_deployment create_k8s_secrets helm_deploy
export -f show_cluster_status helm_cleanup restart_deployments get_pod_logs
