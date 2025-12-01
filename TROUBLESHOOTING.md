# 🔧 Guide de Dépannage - Kubernetes & Minikube

## Problème: Les changements de code n'apparaissent pas après rebuild

### Symptômes
- Vous modifiez le code backend/frontend
- Vous exécutez `./build-images.sh`
- Vous redéployez avec `kubectl rollout restart`
- **Mais l'ancienne version continue de tourner** 😤

### Causes
1. **Cache Docker**: Docker utilise le cache des layers et ne rebuild pas
2. **Cache Minikube**: Minikube garde les anciennes images même après `image load`
3. **imagePullPolicy: IfNotPresent**: Kubernetes ne recharge pas l'image si elle existe déjà

### Solutions

#### Solution 1: Utiliser le script amélioré (RECOMMANDÉ)
Le script `./build-images.sh` a été mis à jour pour:
- Utiliser `--no-cache` pour forcer le rebuild complet
- Supprimer les anciennes images de Minikube avant de charger les nouvelles
- Afficher un rappel pour redémarrer les deployments

```bash
./build-images.sh
kubectl rollout restart deployment/hello-world-backend deployment/hello-world-frontend
```

#### Solution 2: Nettoyer complètement et redéployer
```bash
# 1. Désinstaller le release Helm
helm uninstall hello-world

# 2. Supprimer les anciennes images de Minikube
eval $(minikube docker-env)
docker rmi -f hello-backend:latest hello-frontend:latest
eval $(minikube docker-env -u)

# 3. Rebuilder sans cache
docker build --no-cache -t hello-backend:latest ./backend
docker build --no-cache -t hello-frontend:latest ./frontend

# 4. Charger dans Minikube
minikube image load hello-backend:latest
minikube image load hello-frontend:latest

# 5. Réinstaller
helm install hello-world ./helm
```

#### Solution 3: Utiliser des tags avec timestamp
```bash
# Build avec un tag unique
TAG=$(date +%Y%m%d-%H%M%S)
docker build -t hello-backend:$TAG ./backend
docker build -t hello-frontend:$TAG ./frontend

# Charger dans Minikube
minikube image load hello-backend:$TAG
minikube image load hello-frontend:$TAG

# Mettre à jour les deployments
kubectl set image deployment/hello-world-backend backend=hello-backend:$TAG
kubectl set image deployment/hello-world-frontend frontend=hello-frontend:$TAG
```

#### Solution 4: Forcer imagePullPolicy à Never
Modifier `helm/values.yaml`:
```yaml
backend:
  image:
    pullPolicy: Never  # Au lieu de IfNotPresent

frontend:
  image:
    pullPolicy: Never
```

Puis supprimer et recréer les pods:
```bash
kubectl delete pod -l app=hello-world-backend
kubectl delete pod -l app=hello-world-frontend
```

### Vérifications

#### 1. Vérifier la date du JAR dans le pod
```bash
kubectl exec deployment/hello-world-backend -- ls -la /app/app.jar
```
La date doit correspondre à votre build récent.

#### 2. Vérifier l'image utilisée par le pod
```bash
kubectl get pod -l app=hello-world-backend -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'
```

#### 3. Vérifier les images dans Minikube
```bash
eval $(minikube docker-env)
docker images | grep hello
```

#### 4. Vérifier les logs de démarrage
```bash
# Backend - devrait montrer JPA/Hibernate si PostgreSQL est activé
kubectl logs deployment/hello-world-backend | head -50

# Vérifier que les controllers sont chargés
kubectl logs deployment/hello-world-backend | grep "UserController\|RequestMappingHandlerMapping"
```

## Problème: Backend ne se connecte pas à PostgreSQL

### Symptômes
```
Caused by: java.net.UnknownHostException: postgres-service
```

### Solutions

#### 1. Vérifier que PostgreSQL est déployé
```bash
kubectl get pods -l app=postgres
kubectl get service postgres-service
```

#### 2. Attendre que PostgreSQL soit prêt avant de démarrer le backend
```bash
kubectl wait --for=condition=ready pod -l app=postgres --timeout=60s
kubectl rollout restart deployment/hello-world-backend
```

#### 3. Vérifier la connectivité réseau
```bash
# Depuis le pod backend
kubectl exec deployment/hello-world-backend -- nc -zv postgres-service 5432

# Ou avec nslookup
kubectl exec deployment/hello-world-backend -- nslookup postgres-service
```

#### 4. Vérifier les logs PostgreSQL
```bash
kubectl logs deployment/postgres
```

## Problème: Les pods restent en "Pending"

### Symptômes
```
0/1 nodes are available: 1 Insufficient cpu
```

### Solutions

#### 1. Vérifier les ressources disponibles
```bash
kubectl describe nodes | grep -A 5 "Allocated resources"
kubectl top nodes
```

#### 2. Réduire les ressources demandées
Modifier `helm/values.yaml`:
```yaml
backend:
  resources:
    requests:
      cpu: 100m      # Réduire de 250m à 100m
      memory: 256Mi
```

#### 3. Scaler down les services non essentiels
```bash
kubectl scale deployment logstash --replicas=0
kubectl scale deployment kibana --replicas=0
```

#### 4. Augmenter les ressources du cluster Minikube
```bash
minikube stop
minikube start --cpus=4 --memory=8192
```

## Problème: "404 Not Found" sur les endpoints API

### Symptômes
```bash
curl http://localhost:8081/api/users/count
# Retourne: {"status":404,"error":"Not Found"}
```

### Solutions

#### 1. Vérifier que le contrôleur existe dans le code
```bash
ls backend/src/main/java/com/hello/controller/UserController.java
```

#### 2. Vérifier que l'image a été reconstruite
```bash
# Dans l'image locale
docker run --rm hello-backend:latest sh -c "ls -la /app/app.jar"

# Dans le pod
kubectl exec deployment/hello-world-backend -- ls -la /app/app.jar
```

#### 3. Vérifier les mappings dans les logs
```bash
kubectl logs deployment/hello-world-backend | grep "Mapped"
```

#### 4. Forcer un rebuild complet
```bash
cd backend
mvn clean
cd ..
./build-images.sh
```

## Bonnes Pratiques pour Éviter les Problèmes

### 1. Workflow de Développement Local

```bash
# 1. Modifier le code
# 2. Clean build Maven (si backend)
cd backend && mvn clean && cd ..

# 3. Rebuild les images (script amélioré)
./build-images.sh

# 4. Redéployer
kubectl rollout restart deployment/hello-world-backend
kubectl rollout restart deployment/hello-world-frontend

# 5. Attendre que les pods soient prêts
kubectl wait --for=condition=ready pod -l app=hello-world-backend --timeout=120s

# 6. Tester
kubectl exec deployment/hello-world-backend -- curl http://localhost:8080/api/users/count
```

### 2. Utiliser des alias
Ajoutez à votre `~/.zshrc` ou `~/.bashrc`:
```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgd='kubectl get deployments'
alias kl='kubectl logs'
alias kr='kubectl rollout restart'
alias kw='kubectl wait --for=condition=ready'
```

### 3. Activer l'auto-completion kubectl
```bash
# Dans ~/.zshrc
source <(kubectl completion zsh)
```

### 4. Pour Azure AKS - Utiliser le CI/CD

Au lieu de rebuilder localement, configurez GitHub Actions pour:
1. Builder les images à chaque push
2. Les pousser vers GitHub Container Registry
3. Utiliser `imagePullPolicy: Always` sur AKS

### 5. Variables d'environnement pour le développement

Créer un fichier `.env.local`:
```bash
BACKEND_IMAGE=hello-backend:dev-$(date +%s)
FRONTEND_IMAGE=hello-frontend:dev-$(date +%s)
```

## Commandes Utiles

### Debugging Général
```bash
# Tout l'état du cluster
kubectl get all

# État détaillé d'un pod
kubectl describe pod <pod-name>

# Logs en temps réel
kubectl logs -f deployment/hello-world-backend

# Shell interactif dans un pod
kubectl exec -it deployment/hello-world-backend -- sh

# Port-forward pour tester localement
kubectl port-forward deployment/hello-world-backend 8080:8080
```

### Nettoyage
```bash
# Supprimer tous les pods en erreur
kubectl delete pods --field-selector status.phase=Failed

# Nettoyer les images non utilisées dans Minikube
eval $(minikube docker-env)
docker system prune -a -f
eval $(minikube docker-env -u)

# Reset complet de Minikube
minikube delete
minikube start --cpus=4 --memory=8192
```

### Performance
```bash
# Ressources utilisées par les pods
kubectl top pods

# Ressources par namespace
kubectl top pods --all-namespaces

# Événements récents
kubectl get events --sort-by='.lastTimestamp'
```

## Checklist Avant de Signaler un Bug

- [ ] J'ai vérifié que l'image a bien été reconstruite avec `--no-cache`
- [ ] J'ai supprimé les anciennes images de Minikube
- [ ] J'ai fait `kubectl rollout restart` après le rebuild
- [ ] J'ai attendu que les pods soient en état "Running"
- [ ] J'ai vérifié les logs avec `kubectl logs`
- [ ] J'ai testé la connectivité réseau entre les pods
- [ ] J'ai vérifié que les ressources CPU/RAM sont suffisantes
- [ ] J'ai essayé de supprimer et recréer le pod manuellement

## Ressources Supplémentaires

- [Documentation Kubernetes](https://kubernetes.io/docs/)
- [Minikube Guide](https://minikube.sigs.k8s.io/docs/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Helm Documentation](https://helm.sh/docs/)
