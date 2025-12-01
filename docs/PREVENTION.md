# 🛡️ Guide de Prévention - Problèmes de Cache et Déploiement

Ce guide explique comment éviter les problèmes rencontrés lors du déploiement et fournit les bonnes pratiques.

## 🎯 Résumé des Problèmes Rencontrés

### 1. Cache Docker Local (Minikube)
**Symptôme**: Changements de code non reflétés après rebuild  
**Cause**: Docker utilise le cache des layers  
**Solution**: `--no-cache` dans `build-images.sh` ✅

### 2. Cache Docker Buildx (Azure multi-platform)
**Symptôme**: Images poussées vers GHCR mais code ancien  
**Cause**: Buildx garde son propre cache pour les builds multi-platform  
**Solution**: `--no-cache` dans `build-and-push-azure.sh` ✅

### 3. Rollout Restart sur Petit Cluster
**Symptôme**: `Insufficient CPU` lors du rollout restart  
**Cause**: Kubernetes crée un nouveau pod avant de supprimer l'ancien  
**Solution**: Script `azure-reload-images.sh` qui supprime puis recrée ✅

## 🔧 Scripts Mis à Jour

### `build-images.sh` (Minikube)
```bash
# ✅ Utilise automatiquement --no-cache
# ✅ Nettoie les anciennes images de Minikube
# ✅ Rappelle de faire rollout restart
./build-images.sh
```

### `build-and-push-azure.sh` (Azure)
```bash
# ✅ Utilise automatiquement --no-cache pour backend ET frontend
# ✅ Build multi-platform (linux/amd64, linux/arm64)
# ✅ Pousse directement vers GHCR
./build-and-push-azure.sh
```

### `azure-reload-images.sh` (Nouveau!)
```bash
# ✅ Supprime et recrée les pods au lieu de rollout restart
# ✅ Évite les problèmes de CPU insuffisant
# ✅ Menu interactif (backend, frontend, ou les deux)
./azure-reload-images.sh
```

### `azure-deploy.sh`
```bash
# ✅ Ne fait plus de rollout restart automatique
# ✅ Évite les timeouts sur petits clusters
# ✅ Commentaire avec instructions pour reload manuel
./azure-deploy.sh
```

## 📋 Checklist de Déploiement

### Minikube (Développement Local)

1. **Modifier le code** ✏️
   ```bash
   # Éditer apps/backend/src/... ou apps/frontend/src/...
   ```

2. **Cleaner Maven si backend modifié** 🧹
   ```bash
   cd apps/backend && mvn clean && cd ../..
   ```

3. **Rebuilder les images** 🔨
   ```bash
   ./build-images.sh  # --no-cache automatique
   ```

4. **Redémarrer les pods** 🔄
   ```bash
   kubectl rollout restart deployment/hello-world-backend
   kubectl rollout restart deployment/hello-world-frontend
   ```

5. **Attendre que les pods soient prêts** ⏳
   ```bash
   kubectl wait --for=condition=ready pod -l app=hello-world-backend --timeout=120s
   ```

6. **Tester** ✅
   ```bash
   minikube service hello-world-frontend-service
   ```

### Azure AKS (Production)

1. **Modifier le code** ✏️
   ```bash
   # Éditer apps/backend/src/... ou apps/frontend/src/...
   ```

2. **Cleaner Maven si backend modifié** 🧹
   ```bash
   cd apps/backend && mvn clean && cd ../..
   ```

3. **Rebuilder et pousser** 🔨
   ```bash
   ./build-and-push-azure.sh  # --no-cache automatique
   ```

4. **Recharger les images** 🔄
   ```bash
   ./azure-reload-images.sh
   # Choisir: 1=backend, 2=frontend, 3=les deux
   ```

5. **Vérifier le statut** 📊
   ```bash
   ./azure-status.sh
   ```

6. **Tester l'application** ✅
   ```bash
   # Ouvrir http://<EXTERNAL-IP>
   kubectl get service hello-world-frontend-service
   ```

## 🚨 Situations d'Urgence

### L'ancien code continue de tourner sur Azure

```bash
# Vérifier l'image utilisée
kubectl describe pod -l app=hello-world-backend | grep "Image:"

# Vérifier la date du JAR
kubectl exec deployment/hello-world-backend -- ls -la /app/app.jar

# Forcer le téléchargement de la nouvelle image
kubectl delete pod -l app=hello-world-backend
kubectl delete pod -l app=hello-world-frontend
```

### Pods en Pending (Insufficient CPU)

```bash
# Voir l'utilisation CPU
kubectl describe nodes | grep -A 5 "Allocated resources"

# Scaler down les services non essentiels
kubectl scale deployment/logstash --replicas=0
kubectl scale deployment/kibana --replicas=0

# Annuler un rollout problématique
kubectl rollout undo deployment/nom-du-deployment
```

### PostgreSQL ne démarre pas

```bash
# Vérifier les logs
kubectl logs deployment/postgres

# Vérifier que le backend attend PostgreSQL
kubectl logs deployment/hello-world-backend | grep postgres

# Redémarrer PostgreSQL
kubectl delete pod -l app=postgres
```

## 🎓 Bonnes Pratiques

### 1. Toujours utiliser --no-cache pour les dépendances

Quand vous modifiez:
- `pom.xml` (backend)
- `package.json` (frontend)
- `application.yml` (backend)

Le `--no-cache` est **obligatoire**, il est maintenant automatique dans tous les scripts.

### 2. Vérifier le timestamp après build

```bash
# Minikube
eval $(minikube docker-env)
docker images | grep hello

# Azure (après push)
kubectl exec deployment/hello-world-backend -- ls -la /app/app.jar
```

La date doit correspondre à votre build récent.

### 3. Utiliser imagePullPolicy: Always sur Azure

Déjà configuré dans `helm/values-azure.yaml`:
```yaml
backend:
  image:
    pullPolicy: Always  # ✅ Force le pull à chaque pod restart
```

### 4. Commits réguliers

```bash
git add .
git commit -m "feat: ajout PostgreSQL avec users API"
git push
```

Permet de revenir en arrière facilement si problème.

### 5. Tester localement avant Azure

```bash
# 1. Test sur Minikube
./build-images.sh
./deploy.sh
minikube service hello-world-frontend-service

# 2. Si OK, déployer sur Azure
./build-and-push-azure.sh
./azure-reload-images.sh
```

## 🔍 Commandes de Diagnostic

### Vérifier les images

```bash
# Minikube
eval $(minikube docker-env)
docker images | grep hello

# Azure
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
```

### Vérifier les événements

```bash
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

### Vérifier les ressources

```bash
kubectl top nodes
kubectl top pods
kubectl describe nodes | grep -A 5 "Allocated resources"
```

### Logs en temps réel

```bash
kubectl logs -f deployment/hello-world-backend
kubectl logs -f deployment/hello-world-frontend
kubectl logs -f deployment/postgres
```

## 📚 Références

- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Guide complet de dépannage
- [AZURE.md](AZURE.md) - Guide détaillé Azure AKS
- [POSTGRESQL.md](POSTGRESQL.md) - Documentation PostgreSQL

## ✅ Résumé: Comment se prémunir?

1. ✅ **Scripts mis à jour** avec `--no-cache` automatique
2. ✅ **Nouveau script** `azure-reload-images.sh` pour éviter les problèmes CPU
3. ✅ **Documentation complète** dans TROUBLESHOOTING.md
4. ✅ **Checklist** pour chaque environnement (Minikube, Azure)
5. ✅ **Commandes de diagnostic** pour vérifier que tout est OK

**En suivant ces bonnes pratiques, vous éviterez 99% des problèmes de cache et déploiement!** 🎉
