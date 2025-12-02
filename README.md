# Hello World - Kubernetes Application

Application full-stack déployable sur Minikube ou Azure AKS avec backend Java Spring Boot, frontend Angular, et stack complète (PostgreSQL, RabbitMQ, Elasticsearch, Logstash, Kibana).

## 🚀 Démarrage Rapide

```bash
# 1. Installation initiale
make init

# 2. Configurez vos credentials dans .env
# Éditez .env avec vos informations

# 3. Déploiement local (Minikube)
minikube start
make full-local

# 4. Accéder à l'application
minikube service hello-world-frontend-service
```

## 📋 Commandes Principales

```bash
make help             # Afficher toutes les commandes disponibles

# Développement Local (Minikube)
make build-local      # Construire les images
make deploy-local     # Déployer sur Minikube
make full-local       # Build + Deploy

# Développement Azure (AKS)
make build-azure      # Build et push vers GHCR
make deploy-azure     # Déployer sur Azure
make full-azure       # Build + Deploy

# Utilitaires
make status           # État du cluster
make logs-backend     # Logs du backend
make tunnel           # Tunnels SSH (Azure)
make restart-backend  # Redémarrer le backend
make clean            # Nettoyer l'environnement
```

## 🏗️ Architecture

- **Backend**: Spring Boot (Java 17) - API REST, RabbitMQ, Elasticsearch, PostgreSQL
- **Frontend**: Angular 17 - Interface utilisateur moderne
- **Base de données**: PostgreSQL - Gestion des utilisateurs
- **Message Broker**: RabbitMQ - Communication asynchrone
- **Logs & Analytics**: ELK Stack (Elasticsearch, Logstash, Kibana)

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [`docs/QUICKREF.md`](docs/QUICKREF.md) | ⚡ Référence rapide des commandes |
| [`docs/SCRIPTS.md`](docs/SCRIPTS.md) | 📜 Documentation des scripts et Makefile |
| [`docs/SECRETS.md`](docs/SECRETS.md) | 🔐 Gestion des secrets et mots de passe |
| [`docs/AZURE.md`](docs/AZURE.md) | ☁️ Guide Azure AKS avec Terraform |
| [`docs/INGRESS.md`](docs/INGRESS.md) | 🌐 Exposition publique avec Ingress |
| [`docs/POSTGRESQL.md`](docs/POSTGRESQL.md) | 🐘 Documentation PostgreSQL et API |
| [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) | 🛠️ Résolution des problèmes |
| [`docs/PREVENTION.md`](docs/PREVENTION.md) | 🛡️ Prévention des problèmes de cache |
| [`docs/MIGRATION.md`](docs/MIGRATION.md) | 🔄 Migration vers nouvelle architecture |

## 💰 Coûts Azure

**Configuration Recommandée: ~22-25€/mois**
- VM Standard_B2s (2 vCPU, 4 GB RAM): ~22€/mois
- AKS Free tier: 0€
- Services en ClusterIP (pas de LoadBalancer): 0€
- Stockage + Bande passante: ~3-5€/mois
- Accès via tunnels SSH (gratuit)

## 🛠️ Prérequis

- **Docker** (avec buildx pour multi-platform)
- **Minikube** ou **Azure CLI**
- **Helm 3**
- **kubectl**
- **Terraform** (pour Azure)
- **Java 17+** (développement local)
- **Node.js 20+** (développement local)

```bash
# Installation automatique des prérequis (MacOS)
make install-prereqs
```

## 🔧 Configuration

### Fichier `.env`

Copiez `.env.example` et configurez vos credentials :

```bash
# GitHub Container Registry (pour Azure)
GHCR_USERNAME="your-github-username"
GHCR_TOKEN="ghp_your_token"

# Azure
RESOURCE_GROUP_NAME="rg-hello-world"
CLUSTER_NAME="aks-hello-world"

# Application Secrets
POSTGRES_PASSWORD="your_secure_password"
RABBITMQ_PASSWORD="your_secure_password"
```

## 🌐 Accès aux Services

### Minikube

```bash
# Frontend
minikube service hello-world-frontend-service

# Ou via port-forward
kubectl port-forward service/hello-world-frontend-service 8081:80
# → http://localhost:8081
```

### Azure AKS

```bash
# Créer des tunnels SSH (recommandé - gratuit)
make tunnel

# OU configurer un Ingress pour accès public
make setup-ingress
# Puis déployer
make deploy-azure

# Services accessibles :
# Via tunnels:
# → Frontend:  http://localhost:8080
# → Backend:   http://localhost:8081
# → RabbitMQ:  http://localhost:15672 (guest/guest)
# → Kibana:    http://localhost:5601

# Via Ingress (après configuration DNS):
# → Frontend:  http://votre-domaine.com
```

## 🔍 Développement

### Backend (Java Spring Boot)

```bash
make dev-backend      # Lance le backend en mode dev
make test-backend     # Exécute les tests
```

### Frontend (Angular)

```bash
make dev-frontend     # Lance le frontend en mode dev
make test-frontend    # Exécute les tests
```

## 📊 Monitoring & Debug

```bash
make status           # État du cluster
make logs-backend     # Logs du backend en temps réel
make logs-frontend    # Logs du frontend
make events           # Événements Kubernetes

# Debug avancé
make debug-backend    # Shell dans le pod backend
make describe-backend # Détails du déploiement
DEBUG=true make deploy-local  # Mode debug
```

## 🧹 Nettoyage

```bash
# Nettoyer l'environnement actuel (auto-détecte Minikube/Azure)
make clean

# Nettoyer spécifiquement
make clean-local      # Minikube uniquement
make clean-azure      # Azure (optionnel: détruit l'infra)
make clean-docker     # Images Docker locales
make clean-all        # Nettoyage complet

# Arrêter Minikube
minikube stop
```

## 🎯 Workflows Typiques

### Premier Déploiement Local

```bash
make init             # Configuration initiale
minikube start        # Démarrer Minikube
make full-local       # Build + Deploy
make status           # Vérifier l'état
```

### Développement Quotidien

```bash
# Modifier le code backend ou frontend
make build-local      # Rebuild les images
make restart-backend  # Redémarrer le service
make logs-backend     # Voir les logs
```

### Déploiement Azure

```bash
make init             # Configuration initiale
az login              # Connexion Azure
make full-azure       # Build + Deploy sur Azure
make tunnel           # Accès aux services
```

## 🚨 Dépannage

**Problème**: Pods ne démarrent pas
```bash
make status
make events
make logs-backend
```

**Problème**: Changements de code non visibles
```bash
make build-local      # Rebuild avec --no-cache automatique
make restart-backend  # Force le redémarrage
```

**Problème**: Erreurs de secrets
```bash
make secrets          # Recréer les secrets depuis .env
```

📖 **Guide complet**: [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)

## 📁 Structure du Projet

```
hello-world/
├── Makefile                    # Interface principale
├── .env                        # Configuration (ne pas commiter!)
├── scripts/                    # Scripts organisés
│   ├── lib/                   # Bibliothèques partagées
│   ├── local/                 # Scripts Minikube
│   ├── azure/                 # Scripts Azure
│   └── utils/                 # Utilitaires
├── apps/
│   ├── backend/               # Spring Boot API
│   └── frontend/              # Angular App
├── helm/                      # Kubernetes Charts
├── terraform/                 # Infrastructure as Code
└── docs/                      # Documentation
```

## 📝 Notes Importantes

- Les secrets sont gérés via `.env` et Kubernetes Secrets (jamais hardcodés)
- Les images sont buildées avec `--no-cache` pour éviter les problèmes de cache
- Azure utilise des tunnels SSH pour économiser les coûts de LoadBalancer
- Tous les scripts utilisent une gestion d'erreur robuste (`set -euo pipefail`)

## 🤝 Contribution

Ce projet utilise :
- **Makefile** pour l'interface unifiée
- **Scripts Bash** modulaires et réutilisables
- **Helm** pour le déploiement Kubernetes
- **Terraform** pour l'infrastructure Azure
- **GitHub Container Registry** pour les images Docker

## 📄 Licence

Projet de démonstration - À des fins éducatives

---

**Besoin d'aide ?** Consultez `make help` ou la [documentation complète](docs/)
