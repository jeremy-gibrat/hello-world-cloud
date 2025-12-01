# Documentation des Scripts

## 📁 Structure

```
scripts/
├── lib/                      # Bibliothèques de fonctions partagées
│   ├── common.sh            # Fonctions communes (logging, vérifications)
│   ├── k8s.sh               # Fonctions Kubernetes
│   └── docker.sh            # Fonctions Docker
├── local/                   # Scripts pour Minikube
│   ├── build.sh             # Build des images pour Minikube
│   ├── deploy.sh            # Déploiement sur Minikube
│   └── cleanup.sh           # Nettoyage Minikube
├── azure/                   # Scripts pour Azure AKS
│   ├── build.sh             # Build et push vers GHCR
│   ├── deploy.sh            # Déploiement sur Azure
│   └── cleanup.sh           # Nettoyage Azure
└── utils/                   # Utilitaires
    ├── secrets.sh           # Gestion des secrets
    ├── status.sh            # Affichage de l'état
    └── tunnel.sh            # Tunnels SSH
```

## 🎯 Utilisation Recommandée : Makefile

Au lieu d'appeler directement les scripts, utilisez le **Makefile** :

```bash
# Afficher l'aide
make help

# Environnement local (Minikube)
make build-local      # Build les images
make deploy-local     # Déploie sur Minikube
make full-local       # Build + Deploy

# Environnement Azure (AKS)
make build-azure      # Build et push vers GHCR
make deploy-azure     # Déploie sur Azure
make full-azure       # Build + Deploy

# Utilitaires
make status           # État du cluster
make secrets          # Créer les secrets
make tunnel           # Tunnels SSH
make logs-backend     # Logs du backend

# Maintenance
make restart-backend  # Redémarre le backend
make scale-backend REPLICAS=3  # Scale le backend
make clean            # Nettoyage (auto-détecte l'environnement)
```

## 📚 Bibliothèques Partagées

### `scripts/lib/common.sh`

Fonctions utilitaires communes :

```bash
# Logging avec couleurs
log_info "Message d'information"
log_success "Message de succès"
log_warning "Message d'avertissement"
log_error "Message d'erreur"
log_step "Étape en cours"
log_debug "Message de debug (si DEBUG=true)"

# Vérifications
check_command "docker" "https://docs.docker.com/get-docker/"
check_prerequisites docker kubectl helm

# Configuration
load_env              # Charge les variables depuis .env
check_docker_running  # Vérifie que Docker est démarré

# Utilitaires
confirm "Continuer ?" "yes"  # Demande confirmation
separator             # Affiche une ligne de séparation
run_command "cmd"     # Exécute une commande avec gestion d'erreur
```

### `scripts/lib/k8s.sh`

Fonctions Kubernetes :

```bash
# Contextes
get_k8s_context                    # Obtient le contexte actuel
ensure_minikube_context            # Vérifie qu'on est sur Minikube
ensure_aks_context "cluster-name"  # Configure le contexte AKS

# Déploiement
create_k8s_secrets                 # Crée les secrets depuis .env
helm_deploy "release" "chart" "values.yaml"
wait_for_pods "app=backend" 300    # Attend que les pods soient prêts
wait_for_deployment "backend" 300

# Gestion
show_cluster_status                # Affiche l'état complet
helm_cleanup "release"             # Nettoie les ressources Helm
restart_deployments "backend" "frontend"
get_pod_logs "app=backend" true    # Affiche les logs
```

### `scripts/lib/docker.sh`

Fonctions Docker :

```bash
# Build
setup_buildx "multiplatform"  # Configure buildx
build_image "context" "name" "tag" "platform" "no_cache"
build_and_push_multiplatform "context" "image" "tag" "platforms"

# Minikube
load_image_to_minikube "image" "tag"

# Registry
docker_login "registry" "user" "password"
ghcr_login                    # Connexion GHCR depuis .env

# Fonctions haut niveau
build_local_images "apps/backend/" "apps/frontend/" "img-backend" "img-frontend"
build_azure_images "apps/backend/" "apps/frontend/" "ghcr.io/user"
```

## 🔧 Scripts Locaux (Minikube)

### `scripts/local/build.sh`

Build les images Docker et les charge dans Minikube.

**Utilisation :**
```bash
./scripts/local/build.sh
# ou
make build-local
```

**Ce qu'il fait :**
1. Vérifie que Docker et Minikube sont installés et démarrés
2. Build l'image backend avec `--no-cache`
3. Build l'image frontend avec `--no-cache`
4. Charge les deux images dans Minikube

### `scripts/local/deploy.sh`

Déploie l'application sur Minikube.

**Utilisation :**
```bash
./scripts/local/deploy.sh
# ou
make deploy-local
```

**Ce qu'il fait :**
1. Vérifie qu'on est sur le contexte Minikube
2. Charge les variables depuis `.env`
3. Crée les secrets Kubernetes
4. Déploie avec Helm (chart local)
5. Attend que les pods soient prêts
6. Redémarre les déploiements pour s'assurer d'utiliser les dernières images
7. Affiche l'état du cluster

### `scripts/local/cleanup.sh`

Nettoie l'environnement Minikube.

**Utilisation :**
```bash
./scripts/local/cleanup.sh
# ou
make clean-local
```

**Ce qu'il fait :**
1. Supprime le release Helm
2. Supprime les secrets Kubernetes

## ☁️ Scripts Azure (AKS)

### `scripts/azure/build.sh`

Build les images multi-platform et les push vers GHCR.

**Utilisation :**
```bash
./scripts/azure/build.sh
# ou
make build-azure
```

**Ce qu'il fait :**
1. Vérifie que Docker est installé et démarré
2. Charge les credentials GHCR depuis `.env`
3. Se connecte à ghcr.io
4. Build backend (linux/amd64 + linux/arm64) et push
5. Build frontend (linux/amd64 + linux/arm64) et push

### `scripts/azure/deploy.sh`

Déploie l'application sur Azure AKS.

**Utilisation :**
```bash
./scripts/azure/deploy.sh
# ou
make deploy-azure
```

**Ce qu'il fait :**
1. Vérifie les prérequis (terraform, az, kubectl, helm)
2. Vérifie la connexion Azure
3. (Optionnel) Build et push des images
4. Génère `terraform.tfvars` si nécessaire
5. Exécute `terraform plan`
6. Demande confirmation
7. Applique `terraform apply`
8. Récupère les credentials AKS
9. Configure le contexte kubectl
10. Crée les secrets Kubernetes
11. Déploie avec Helm (values-azure.yaml)
12. Attend que les pods soient prêts
13. Affiche l'état

### `scripts/azure/cleanup.sh`

Nettoie l'environnement Azure.

**Utilisation :**
```bash
./scripts/azure/cleanup.sh
# ou
make clean-azure
```

**Ce qu'il fait :**
1. Supprime le release Helm
2. Supprime les secrets Kubernetes
3. (Optionnel) Détruit l'infrastructure Terraform

## 🛠️ Scripts Utilitaires

### `scripts/utils/secrets.sh`

Crée ou met à jour les secrets Kubernetes depuis `.env`.

**Utilisation :**
```bash
./scripts/utils/secrets.sh
# ou
make secrets
```

### `scripts/utils/status.sh`

Affiche l'état complet du cluster.

**Utilisation :**
```bash
./scripts/utils/status.sh
# ou
make status
```

**Affiche :**
- Contexte Kubernetes actuel
- Liste des pods
- Liste des services
- Liste des déploiements

### `scripts/utils/tunnel.sh`

Crée des tunnels SSH vers les services Azure.

**Utilisation :**
```bash
./scripts/utils/tunnel.sh
# ou
make tunnel
```

**Tunnels créés :**
- Frontend: http://localhost:8080
- Backend: http://localhost:8081
- RabbitMQ: http://localhost:15672
- Kibana: http://localhost:5601

Appuyez sur `Ctrl+C` pour arrêter.

## 🔒 Variables d'Environnement

Toutes les scripts utilisent les variables définies dans `.env` :

```bash
# GitHub Container Registry
GHCR_USERNAME="your-username"
GHCR_TOKEN="ghp_your_token"

# Azure
RESOURCE_GROUP_NAME="rg-hello-world"
CLUSTER_NAME="aks-hello-world"
LOCATION="francecentral"
# ...

# Application Secrets
POSTGRES_DB="hellodb"
POSTGRES_USER="hellouser"
POSTGRES_PASSWORD="your_password"
RABBITMQ_USER="admin"
RABBITMQ_PASSWORD="your_password"
```

## 🐛 Mode Debug

Activez le mode debug pour voir les commandes exécutées :

```bash
DEBUG=true ./scripts/local/deploy.sh
DEBUG=true make deploy-local
```

## 📋 Workflow Recommandé

### Développement Local

```bash
# 1. Configuration initiale
make init

# 2. Démarrer Minikube
minikube start

# 3. Build et déployer
make full-local

# 4. Accéder à l'application
minikube service hello-world-frontend-service

# 5. Voir les logs
make logs-backend
make logs-frontend

# 6. Redémarrer après changements
make build-local
make restart-backend

# 7. Nettoyage
make clean-local
minikube stop
```

### Déploiement Azure

```bash
# 1. Configuration initiale
make init
az login

# 2. Build et déployer
make full-azure

# 3. Créer des tunnels
make tunnel

# 4. Voir les logs
make logs-backend

# 5. Redéployer après changements
make build-azure
make restart-backend

# 6. Nettoyage
make clean-azure
```

## 🔄 Migration depuis les anciens scripts

Les anciens scripts à la racine peuvent être supprimés ou gardés comme wrappers :

```bash
# Ancien
./deploy.sh

# Nouveau (recommandé)
make deploy-local

# Ou créer un wrapper simple:
#!/bin/bash
make deploy-local
```

## 🚀 Avantages de cette Architecture

✅ **Code réutilisable** : Fonctions communes dans `lib/`  
✅ **Maintenable** : Séparation locale/azure  
✅ **Testable** : Fonctions isolées  
✅ **Documenté** : Logging clair avec couleurs  
✅ **Robuste** : Gestion d'erreur avec `set -euo pipefail`  
✅ **Flexible** : Variables d'environnement  
✅ **Interface unifiée** : Makefile avec auto-complétion  
✅ **CI/CD ready** : Cibles `ci-*` dédiées  

## 📚 Références

- [Bash Best Practices](https://bertvv.github.io/cheat-sheets/Bash.html)
- [Makefile Tutorial](https://makefiletutorial.com/)
- [Kubernetes Scripts Best Practices](https://kubernetes.io/docs/reference/kubectl/)
