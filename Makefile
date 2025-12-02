.PHONY: help build-local deploy-local clean-local build-azure deploy-azure clean-azure status tunnel secrets dev-backend dev-frontend

# Variables
PROJECT_NAME := hello-world
RELEASE_NAME := hello-world
HELM_CHART := ./helm
BACKEND_DIR := ./apps/backend
FRONTEND_DIR := ./apps/frontend

# Couleurs pour l'affichage
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
CYAN := \033[0;36m
RESET := \033[0m

##@ Général

help: ## Afficher cette aide
	@echo "$(CYAN)════════════════════════════════════════════════════════════════════════$(RESET)"
	@echo "$(GREEN)  Hello World - Kubernetes Deployment$(RESET)"
	@echo "$(CYAN)════════════════════════════════════════════════════════════════════════$(RESET)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf ""} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  $(CYAN)%-20s$(RESET) %s\n", $$1, $$2 } \
		/^##@/ { printf "\n$(YELLOW)%s$(RESET)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(CYAN)════════════════════════════════════════════════════════════════════════$(RESET)"
	@echo "$(BLUE)📖 Documentation:$(RESET)"
	@echo "  - docs/QUICKREF.md       - Référence rapide"
	@echo "  - docs/SECRETS.md        - Gestion des secrets"
	@echo "  - docs/SCRIPTS.md        - Documentation des scripts"
	@echo "  - docs/TROUBLESHOOTING.md - Résolution des problèmes"
	@echo "$(CYAN)════════════════════════════════════════════════════════════════════════$(RESET)"

##@ Développement Local (Minikube)

build-local: ## Construire les images Docker pour Minikube
	@./scripts/local/build.sh

deploy-local: ## Déployer sur Minikube
	@./scripts/local/deploy.sh

clean-local: ## Nettoyer l'environnement Minikube
	@./scripts/local/cleanup.sh

full-local: build-local deploy-local ## Build + Deploy sur Minikube

##@ Développement Azure (AKS)

build-azure: ## Construire et pousser les images vers GHCR
	@./scripts/azure/build.sh

deploy-azure: ## Déployer sur Azure AKS
	@./scripts/azure/deploy.sh

clean-azure: ## Nettoyer l'environnement Azure
	@./scripts/azure/cleanup.sh

full-azure: build-azure deploy-azure ## Build + Deploy sur Azure

setup-ingress: ## Configurer l'Ingress sur Azure (exposition publique)
	@./scripts/azure/setup-ingress.sh

##@ Utilitaires

status: ## Afficher l'état du cluster Kubernetes
	@./scripts/utils/status.sh

secrets: ## Créer/mettre à jour les secrets Kubernetes
	@./scripts/utils/secrets.sh

tunnel: ## Créer des tunnels vers les services (Azure)
	@./scripts/utils/tunnel.sh

portainer: ## Ouvrir Portainer (interface web de gestion K8s)
	@echo "$(GREEN)🐳 Ouverture de Portainer...$(RESET)"
	@echo "$(CYAN)Accédez à: http://localhost:9000$(RESET)"
	@kubectl port-forward -n portainer svc/portainer 9000:9000

logs-backend: ## Afficher les logs du backend
	@kubectl logs -f -l app=hello-world-backend

logs-frontend: ## Afficher les logs du frontend
	@kubectl logs -f -l app=hello-world-frontend

logs-rabbitmq: ## Afficher les logs de RabbitMQ
	@kubectl logs -f -l app=rabbitmq

logs-postgres: ## Afficher les logs de PostgreSQL
	@kubectl logs -f -l app=postgres

##@ Développement Application

dev-backend: ## Lancer le backend en mode dev (local)
	@cd $(BACKEND_DIR) && ./mvnw spring-boot:run

dev-frontend: ## Lancer le frontend en mode dev (local)
	@cd $(FRONTEND_DIR) && npm install && npm start

test-backend: ## Exécuter les tests du backend
	@cd $(BACKEND_DIR) && ./mvnw test

test-frontend: ## Exécuter les tests du frontend
	@cd $(FRONTEND_DIR) && npm test

##@ Maintenance

restart-backend: ## Redémarrer le backend
	@kubectl rollout restart deployment/$(RELEASE_NAME)-backend

restart-frontend: ## Redémarrer le frontend
	@kubectl rollout restart deployment/$(RELEASE_NAME)-frontend

restart-all: ## Redémarrer tous les déploiements
	@kubectl rollout restart deployment/$(RELEASE_NAME)-backend
	@kubectl rollout restart deployment/$(RELEASE_NAME)-frontend
	@kubectl rollout restart deployment/rabbitmq
	@kubectl rollout restart deployment/postgres

scale-backend: ## Scaler le backend (ex: make scale-backend REPLICAS=3)
	@kubectl scale deployment/$(RELEASE_NAME)-backend --replicas=$${REPLICAS:-2}

scale-frontend: ## Scaler le frontend (ex: make scale-frontend REPLICAS=3)
	@kubectl scale deployment/$(RELEASE_NAME)-frontend --replicas=$${REPLICAS:-2}

##@ Nettoyage

clean: ## Nettoyer l'environnement actuel (détecte auto Minikube/Azure)
	@if kubectl config current-context | grep -q "minikube"; then \
		$(MAKE) clean-local; \
	else \
		$(MAKE) clean-azure; \
	fi

clean-docker: ## Nettoyer les images Docker locales
	@docker image prune -f
	@docker system prune -f

clean-all: clean clean-docker ## Nettoyage complet (K8s + Docker)

##@ Debug

debug-backend: ## Se connecter au pod backend
	@kubectl exec -it deployment/$(RELEASE_NAME)-backend -- /bin/sh

debug-frontend: ## Se connecter au pod frontend
	@kubectl exec -it deployment/$(RELEASE_NAME)-frontend -- /bin/sh

debug-postgres: ## Se connecter au pod PostgreSQL
	@kubectl exec -it deployment/postgres -- psql -U hellouser -d hellodb

describe-backend: ## Décrire le pod backend
	@kubectl describe deployment/$(RELEASE_NAME)-backend

describe-frontend: ## Décrire le pod frontend
	@kubectl describe deployment/$(RELEASE_NAME)-frontend

events: ## Afficher les événements Kubernetes récents
	@kubectl get events --sort-by=.metadata.creationTimestamp

##@ Terraform

tf-init: ## Initialiser Terraform
	@cd terraform && terraform init

tf-plan: ## Planifier les changements Terraform
	@cd terraform && terraform plan

tf-apply: ## Appliquer les changements Terraform
	@cd terraform && terraform apply

tf-destroy: ## Détruire l'infrastructure Terraform
	@cd terraform && terraform destroy

##@ CI/CD

ci-test: test-backend test-frontend ## Exécuter tous les tests (pour CI)

ci-build: ## Build pour CI/CD
	@echo "🔨 Build CI/CD..."
	@./scripts/azure/build.sh

ci-deploy: ## Déploiement pour CI/CD
	@echo "🚀 Déploiement CI/CD..."
	@./scripts/azure/deploy.sh

##@ Installation

install-prereqs: ## Vérifier/Installer les prérequis (MacOS)
	@echo "$(BLUE)Vérification des prérequis...$(RESET)"
	@command -v docker >/dev/null 2>&1 || (echo "❌ Docker manquant. Installez Docker Desktop" && exit 1)
	@command -v kubectl >/dev/null 2>&1 || (echo "📦 Installation de kubectl..." && brew install kubectl)
	@command -v helm >/dev/null 2>&1 || (echo "📦 Installation de helm..." && brew install helm)
	@command -v minikube >/dev/null 2>&1 || (echo "📦 Installation de minikube..." && brew install minikube)
	@command -v az >/dev/null 2>&1 || (echo "📦 Installation de Azure CLI..." && brew install azure-cli)
	@command -v terraform >/dev/null 2>&1 || (echo "📦 Installation de terraform..." && brew install terraform)
	@echo "$(GREEN)✅ Tous les prérequis sont installés$(RESET)"

setup-env: ## Créer le fichier .env depuis .env.example
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(GREEN)✅ Fichier .env créé. Veuillez le configurer.$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️  .env existe déjà$(RESET)"; \
	fi

init: install-prereqs setup-env ## Configuration initiale complète
	@echo "$(GREEN)✅ Configuration initiale terminée!$(RESET)"
	@echo "$(BLUE)Prochaines étapes:$(RESET)"
	@echo "  1. Configurez .env avec vos credentials"
	@echo "  2. make build-local && make deploy-local (pour Minikube)"
	@echo "  3. make build-azure && make deploy-azure (pour Azure)"
