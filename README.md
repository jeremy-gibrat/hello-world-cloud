# Hello World - Kubernetes avec Helm

Application complète déployée sur Minikube ou Azure AKS avec backend Java Spring Boot, frontend Angular, RabbitMQ et stack ELK (Elasticsearch, Logstash, Kibana).

## 📋 Prérequis

- Docker avec buildx (multi-platform)
- Minikube ou Azure CLI
- Helm 3
- kubectl
- Terraform (pour Azure)
- Java 17+ (pour développement local)
- Node.js 20+ (pour développement local)

## 🏗️ Architecture

- **Backend**: Spring Boot (Java 17) avec API REST, RabbitMQ, Elasticsearch et PostgreSQL
- **Frontend**: Angular 17 avec sections RabbitMQ, Elasticsearch et PostgreSQL
- **PostgreSQL**: Base de données avec gestion des utilisateurs
- **RabbitMQ**: Message broker avec interface admin
- **Elasticsearch**: Moteur de recherche et stockage de logs
- **Logstash**: Pipeline d'ingestion de logs
- **Kibana**: Interface de visualisation Elasticsearch

## 📚 Documentation

- [⚡ QUICKREF.md](QUICKREF.md) - **Référence rapide des commandes**
- [🚀 AZURE.md](AZURE.md) - Guide complet Azure AKS avec Terraform
- [🐘 POSTGRESQL.md](POSTGRESQL.md) - Documentation PostgreSQL et API users
- [🛠️ TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Résolution des problèmes courants
- [🛡️ PREVENTION.md](PREVENTION.md) - **Comment éviter les problèmes de cache**

## 💰 Coûts Azure (Configuration Optimale)

**Configuration Recommandée: ~22-25€/mois**
- **VM**: Standard_B2s (2 vCPU, 4 GB RAM) - ~22€/mois
- **AKS**: Free tier - 0€
- **Services**: Tous en ClusterIP (pas de LoadBalancer) - 0€
- **Stockage + Bande passante**: ~3-5€/mois
- **Accès**: Via tunnel SSH/kubectl port-forward

**Alternatives:**
- Standard_B1s (1 vCPU, 1 GB): ~10€/mois - Trop juste pour ELK
- Standard_B2s_v2 (2 vCPU, 8 GB): ~30€/mois - Marge confortable
- Standard_D2s_v3 (2 vCPU, 8 GB): ~35€/mois - Meilleure performance

## 🚀 Déploiement Azure AKS

### 1. Configuration Terraform

Éditez `terraform/terraform.tfvars` avec vos informations:
```bash
ghcr_username = "votre-username-github"
ghcr_token    = "ghp_votre_token_github"
```

### 2. Créer l'infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 3. Construire et publier les images

```bash
./build-images.sh
```

### 4. Déployer l'application

```bash
./azure-deploy.sh
```

### 5. Accéder aux services via tunnel

```bash
./tunnel.sh
```

Cette commande crée des tunnels vers:
- **Frontend**: http://localhost:8080
- **Backend API**: http://localhost:8081
- **RabbitMQ Admin**: http://localhost:15672 (guest/guest)
- **Kibana**: http://localhost:5601

Appuyez sur `Ctrl+C` pour arrêter les tunnels.

## 🚇 Utilisation du tunnel

Le script `tunnel.sh` remplace les LoadBalancers coûteux (~36€/mois) par des tunnels SSH gratuits:

```bash
# Démarrer tous les tunnels
./tunnel.sh

# Dans un autre terminal, vous pouvez aussi créer des tunnels individuels
kubectl port-forward service/hello-world-frontend-service 8080:80
kubectl port-forward service/rabbitmq-service 15672:15672
kubectl port-forward service/kibana-service 5601:5601
```

## 🚀 Déploiement Minikube (Local)

### 1. Démarrer Minikube

```bash
minikube start
```

### 2. Construire et charger les images Docker

```bash
chmod +x build-images.sh
./build-images.sh
```

Cette commande:
- Construit l'image Docker du backend
- Construit l'image Docker du frontend
- Charge les images dans Minikube

### 3. Déployer avec Helm

```bash
chmod +x deploy.sh
./deploy.sh
```

Cette commande:
- Installe ou met à jour le chart Helm
- Attend que les pods soient prêts
- Affiche l'état du déploiement

### 4. Accéder à l'application

Option 1 - Via Minikube service:
```bash
minikube service hello-world-frontend-service
```

Option 2 - Via port-forward:
```bash
kubectl port-forward service/hello-world-frontend-service 8081:80
```
Puis ouvrez http://localhost:8081 dans votre navigateur.

## 📊 Commandes utiles

### Vérifier le statut
```bash
chmod +x status.sh
./status.sh
```

### Voir les logs en temps réel
```bash
# Backend
kubectl logs -f -l app=hello-world-backend

# Frontend
kubectl logs -f -l app=hello-world-frontend
```

### Redémarrer les pods
```bash
kubectl rollout restart deployment/hello-world-backend
kubectl rollout restart deployment/hello-world-frontend
```

### Nettoyer le déploiement
```bash
chmod +x cleanup.sh
./cleanup.sh
```

## 🔧 Développement local

### Backend

```bash
cd backend
./mvnw spring-boot:run
```

L'API sera disponible sur http://localhost:8080/api/hello

### Frontend

```bash
cd frontend
npm install
npm start
```

L'application sera disponible sur http://localhost:4200

## 🎨 Structure du projet

```
hello-world/
├── backend/                    # Application Spring Boot
│   ├── src/
│   ├── pom.xml
│   └── Dockerfile
├── frontend/                   # Application Angular
│   ├── src/
│   ├── package.json
│   ├── nginx.conf
│   └── Dockerfile
├── helm/                       # Chart Helm
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── backend-deployment.yaml
│       ├── backend-service.yaml
│       ├── frontend-deployment.yaml
│       └── frontend-service.yaml
├── build-images.sh            # Script de build
├── deploy.sh                  # Script de déploiement
├── cleanup.sh                 # Script de nettoyage
├── status.sh                  # Script de statut
└── README.md
```

## 🔍 Configuration Helm

Le chart Helm peut être personnalisé via `helm/values.yaml`:

```yaml
backend:
  replicaCount: 1              # Nombre de réplicas backend
  image:
    repository: hello-backend
    tag: latest

frontend:
  replicaCount: 1              # Nombre de réplicas frontend
  service:
    nodePort: 30080           # Port NodePort
```

### Déployer avec des valeurs personnalisées

```bash
helm upgrade --install hello-world ./helm \
  --set backend.replicaCount=2 \
  --set frontend.replicaCount=2
```

## 🐛 Dépannage

### Les pods ne démarrent pas

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Les images ne sont pas trouvées

Vérifiez que les images sont bien dans Minikube:
```bash
minikube image ls | grep hello
```

Si besoin, rechargez-les:
```bash
./build-images.sh
```

### Le frontend ne peut pas contacter le backend

Vérifiez que le service backend est accessible:
```bash
kubectl get svc hello-backend-service
kubectl exec -it <frontend-pod> -- curl http://hello-backend-service:8080/api/hello
```

## 📦 Reconstruire et redéployer

### Minikube (local)
```bash
./build-images.sh
./deploy.sh
```

### Azure AKS
```bash
# Rebuilder et pousser les images (--no-cache automatique)
./build-and-push-azure.sh

# Recharger les images sur le cluster
./azure-reload-images.sh

# Vérifier le statut
./azure-status.sh
```

## ⚠️ Problèmes fréquents et solutions

### Cache Docker qui empêche les changements

**Symptôme**: Modifications de code non visibles après rebuild

**Solutions**:
- **Minikube**: Utilisez `./build-images.sh` (--no-cache automatique)
- **Azure**: Utilisez `./build-and-push-azure.sh` (--no-cache automatique)
- Consultez [TROUBLESHOOTING.md](TROUBLESHOOTING.md) pour plus de détails

### Rollout restart échoue sur Azure (Insufficient CPU)

**Symptôme**: `kubectl rollout restart` timeout avec erreur CPU

**Solution**: Utilisez `./azure-reload-images.sh` qui supprime/recrée les pods un par un

### Image non mise à jour sur Azure

**Cause**: Cache buildx multi-platform

**Solution**: Le flag `--no-cache` est maintenant automatique dans `build-and-push-azure.sh`

📖 **Guide complet**: Consultez [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## 🛑 Arrêter l'application

```bash
./cleanup.sh
minikube stop
```

## 📝 Notes

- Le backend expose une API REST sur `/api/hello`
- Le frontend appelle automatiquement le backend au démarrage
- Les images Docker utilisent le multi-stage build pour optimiser la taille
- Les health checks sont configurés pour Kubernetes (liveness et readiness probes)

## 🎯 Endpoints

- Frontend: http://<minikube-ip>:30080
- Backend API: http://hello-backend-service:8080/api/hello (interne au cluster)
