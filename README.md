# Hello World - Kubernetes avec Helm

Application simple déployée sur Minikube avec un backend Java Spring Boot et un frontend Angular.

## 📋 Prérequis

- Docker
- Minikube
- Helm 3
- kubectl
- Java 17+ (pour développement local)
- Node.js 20+ (pour développement local)

## 🏗️ Architecture

- **Backend**: Spring Boot (Java 17) exposant une API REST sur le port 8080
- **Frontend**: Angular 17 avec Nginx sur le port 80
- **Déploiement**: Kubernetes via Helm sur Minikube

## 🚀 Démarrage rapide

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

```bash
./build-images.sh
./deploy.sh
```

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
