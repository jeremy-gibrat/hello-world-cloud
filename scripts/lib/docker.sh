#!/bin/bash

# Bibliothèque de fonctions Docker

# Charger les fonctions communes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Configuration du builder buildx
setup_buildx() {
    local builder_name="${1:-multiplatform}"
    
    log_step "Configuration de Docker buildx..."
    
    if docker buildx inspect "$builder_name" &>/dev/null; then
        log_debug "Builder '$builder_name' existe déjà, utilisation..."
        docker buildx use "$builder_name"
    else
        log_info "Création du builder '$builder_name'..."
        docker buildx create --name "$builder_name" --use
        docker buildx inspect --bootstrap
        log_success "Builder '$builder_name' créé"
    fi
}

# Construire une image Docker
build_image() {
    local context_path="$1"
    local image_name="$2"
    local tag="${3:-latest}"
    local platform="${4:-}"
    local no_cache="${5:-false}"
    
    log_step "Build de l'image: $image_name:$tag"
    
    local build_cmd="docker build"
    
    if [ -n "$platform" ]; then
        # Build multi-platform avec buildx
        build_cmd="docker buildx build --platform $platform"
    fi
    
    if [ "$no_cache" = "true" ]; then
        build_cmd="$build_cmd --no-cache"
    fi
    
    build_cmd="$build_cmd -t $image_name:$tag $context_path"
    
    log_debug "Commande Docker: $build_cmd"
    
    if eval "$build_cmd"; then
        log_success "Image buildée: $image_name:$tag"
        return 0
    else
        log_error "Échec du build de l'image: $image_name"
        return 1
    fi
}

# Construire et pousser une image multi-platform
build_and_push_multiplatform() {
    local context_path="$1"
    local image_name="$2"
    local tag="${3:-latest}"
    local platforms="${4:-linux/amd64,linux/arm64}"
    
    log_step "Build et push multi-platform: $image_name:$tag"
    log_info "Plateformes: $platforms"
    
    setup_buildx
    
    local build_cmd="docker buildx build \
        --no-cache \
        --platform $platforms \
        -t $image_name:$tag \
        --push \
        $context_path"
    
    log_debug "Commande Docker: $build_cmd"
    
    if eval "$build_cmd"; then
        log_success "Image buildée et poussée: $image_name:$tag"
        return 0
    else
        log_error "Échec du build/push: $image_name"
        return 1
    fi
}

# Charger une image dans Minikube
load_image_to_minikube() {
    local image_name="$1"
    local tag="${2:-latest}"
    
    log_step "Chargement de l'image dans Minikube: $image_name:$tag"
    
    if minikube image load "$image_name:$tag"; then
        log_success "Image chargée dans Minikube"
        return 0
    else
        log_error "Échec du chargement dans Minikube"
        return 1
    fi
}

# Se connecter à un registry Docker
docker_login() {
    local registry="$1"
    local username="$2"
    local password="$3"
    
    log_step "Connexion à $registry..."
    
    if echo "$password" | docker login "$registry" -u "$username" --password-stdin; then
        log_success "Connecté à $registry"
        return 0
    else
        log_error "Échec de la connexion à $registry"
        return 1
    fi
}

# Se connecter à GitHub Container Registry
ghcr_login() {
    local username="${GHCR_USERNAME:-}"
    local token="${GHCR_TOKEN:-}"
    
    if [ -z "$username" ] || [ -z "$token" ]; then
        log_error "GHCR_USERNAME ou GHCR_TOKEN non défini dans .env"
        return 1
    fi
    
    docker_login "ghcr.io" "$username" "$token"
}

# Lister les images Docker
list_images() {
    local filter="${1:-}"
    
    if [ -n "$filter" ]; then
        docker images | grep "$filter"
    else
        docker images
    fi
}

# Nettoyer les images Docker
cleanup_images() {
    log_step "Nettoyage des images Docker non utilisées..."
    
    docker image prune -f
    
    log_success "Images nettoyées"
}

# Vérifier qu'une image existe
image_exists() {
    local image_name="$1"
    local tag="${2:-latest}"
    
    if docker image inspect "$image_name:$tag" &>/dev/null; then
        log_debug "Image trouvée: $image_name:$tag"
        return 0
    else
        log_debug "Image non trouvée: $image_name:$tag"
        return 1
    fi
}

# Construire les images backend et frontend pour Minikube
build_local_images() {
    local backend_dir="$1"
    local frontend_dir="$2"
    local backend_image="${3:-hello-backend}"
    local frontend_image="${4:-hello-frontend}"
    
    # Tag avec timestamp pour forcer le rechargement
    local tag="$(date +%Y%m%d-%H%M%S)"
    
    separator
    log_step "Build des images Docker locales"
    log_info "Tag: $tag"
    separator
    
    # Backend
    build_image "$backend_dir" "$backend_image" "$tag" "" "true"
    load_image_to_minikube "$backend_image" "$tag"
    
    # Frontend
    build_image "$frontend_dir" "$frontend_image" "$tag" "" "true"
    load_image_to_minikube "$frontend_image" "$tag"
    
    # Sauvegarder le tag dans un fichier pour le déploiement
    echo "$tag" > "$PROJECT_ROOT/.image-tag"
    
    separator
    log_success "Images locales buildées et chargées dans Minikube"
    log_info "Tag des images: $tag"
    separator
}

# Construire et pousser les images pour Azure
build_azure_images() {
    local backend_dir="$1"
    local frontend_dir="$2"
    local ghcr_repo="$3"
    
    separator
    log_step "Build et push des images vers GHCR"
    separator
    
    ghcr_login || return 1
    
    local backend_image="$ghcr_repo/hello-backend"
    local frontend_image="$ghcr_repo/hello-frontend"
    
    # Backend
    build_and_push_multiplatform "$backend_dir" "$backend_image" "latest"
    
    # Frontend
    build_and_push_multiplatform "$frontend_dir" "$frontend_image" "latest"
    
    separator
    log_success "Images buildées et poussées vers GHCR"
    log_info "Backend:  $backend_image:latest"
    log_info "Frontend: $frontend_image:latest"
    separator
}

# Exporter les fonctions
export -f setup_buildx build_image build_and_push_multiplatform
export -f load_image_to_minikube docker_login ghcr_login
export -f list_images cleanup_images image_exists
export -f build_local_images build_azure_images
