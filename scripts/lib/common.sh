#!/bin/bash

# Bibliothèque de fonctions communes pour tous les scripts

# Couleurs pour l'affichage
export COLOR_RESET='\033[0m'
export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_YELLOW='\033[0;33m'
export COLOR_BLUE='\033[0;34m'
export COLOR_MAGENTA='\033[0;35m'
export COLOR_CYAN='\033[0;36m'

# Fonctions de logging
log_info() {
    echo -e "${COLOR_BLUE}ℹ️  $1${COLOR_RESET}"
}

log_success() {
    echo -e "${COLOR_GREEN}✅ $1${COLOR_RESET}"
}

log_warning() {
    echo -e "${COLOR_YELLOW}⚠️  $1${COLOR_RESET}"
}

log_error() {
    echo -e "${COLOR_RED}❌ $1${COLOR_RESET}"
}

log_step() {
    echo -e "${COLOR_CYAN}🚀 $1${COLOR_RESET}"
}

log_debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        echo -e "${COLOR_MAGENTA}🔍 DEBUG: $1${COLOR_RESET}"
    fi
}

# Fonction pour afficher une barre de séparation
separator() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Vérifier qu'une commande existe
check_command() {
    local cmd=$1
    local install_url=$2
    
    if ! command -v "$cmd" &> /dev/null; then
        log_error "$cmd n'est pas installé"
        if [ -n "$install_url" ]; then
            log_info "Installez-le depuis: $install_url"
        fi
        return 1
    fi
    log_debug "$cmd est installé"
    return 0
}

# Vérifier tous les prérequis
check_prerequisites() {
    local -a commands=("$@")
    local all_ok=true
    
    log_step "Vérification des prérequis..."
    
    for cmd in "${commands[@]}"; do
        case "$cmd" in
            docker)
                check_command docker "https://docs.docker.com/get-docker/" || all_ok=false
                ;;
            kubectl)
                check_command kubectl "https://kubernetes.io/docs/tasks/tools/" || all_ok=false
                ;;
            helm)
                check_command helm "https://helm.sh/docs/intro/install/" || all_ok=false
                ;;
            az)
                check_command az "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" || all_ok=false
                ;;
            terraform)
                check_command terraform "https://www.terraform.io/downloads" || all_ok=false
                ;;
            minikube)
                check_command minikube "https://minikube.sigs.k8s.io/docs/start/" || all_ok=false
                ;;
            *)
                check_command "$cmd" || all_ok=false
                ;;
        esac
    done
    
    if [ "$all_ok" = true ]; then
        log_success "Tous les prérequis sont installés"
        return 0
    else
        log_error "Certains prérequis sont manquants"
        return 1
    fi
}

# Charger les variables depuis .env
load_env() {
    local env_file="${1:-.env}"
    
    if [ ! -f "$env_file" ]; then
        log_error "Fichier $env_file non trouvé"
        log_info "Copiez .env.example vers .env et configurez-le:"
        log_info "  cp .env.example .env"
        return 1
    fi
    
    log_debug "Chargement de la configuration depuis $env_file"
    
    # Exporter les variables en évitant les commentaires et lignes vides
    set -a
    source "$env_file"
    set +a
    
    log_success "Configuration chargée depuis $env_file"
    return 0
}

# Demander confirmation à l'utilisateur
confirm() {
    local message="$1"
    local default="${2:-no}"
    
    if [ "$default" = "yes" ]; then
        read -p "$message (yes/no) [yes]: " response
        response=${response:-yes}
    else
        read -p "$message (yes/no) [no]: " response
        response=${response:-no}
    fi
    
    if [ "$response" = "yes" ] || [ "$response" = "y" ]; then
        return 0
    else
        return 1
    fi
}

# Afficher un spinner pendant l'exécution d'une commande
spinner() {
    local pid=$1
    local message=$2
    local spin='-\|/'
    local i=0
    
    echo -n "$message "
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r$message ${spin:$i:1}"
        sleep .1
    done
    printf "\r$message ✓\n"
}

# Exécuter une commande avec gestion d'erreur
run_command() {
    local cmd="$1"
    local error_msg="${2:-Échec de la commande}"
    
    log_debug "Exécution: $cmd"
    
    if eval "$cmd"; then
        return 0
    else
        log_error "$error_msg"
        return 1
    fi
}

# Vérifier que Docker est démarré
check_docker_running() {
    if ! docker info &> /dev/null; then
        log_error "Docker n'est pas démarré"
        log_info "Lancez Docker Desktop et réessayez"
        return 1
    fi
    log_debug "Docker est démarré"
    return 0
}

# Nettoyer et quitter en cas d'erreur
cleanup_on_error() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Script interrompu avec le code d'erreur: $exit_code"
        # Ajouter ici les actions de nettoyage si nécessaire
    fi
    exit $exit_code
}

# Trap pour nettoyer en cas d'erreur
trap cleanup_on_error EXIT

# Activer le mode strict
set -euo pipefail

# Exporter les fonctions pour qu'elles soient disponibles dans les sous-shells
export -f log_info log_success log_warning log_error log_step log_debug
export -f separator check_command check_prerequisites load_env confirm
export -f spinner run_command check_docker_running
