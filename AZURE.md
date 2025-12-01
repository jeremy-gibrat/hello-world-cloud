# Déploiement sur Azure Kubernetes Service (AKS)

Guide complet pour déployer votre application sur Azure AKS en utilisant Terraform, avec vos images Docker depuis GitHub Container Registry.

## 💰 Estimation des coûts

**Configuration minimale (tests) :**
- AKS Control Plane : **GRATUIT** (tier Free)
- 1 node Standard_B2s : **~30€/mois** (~1€/jour)
- 1 node Standard_B1s : **~10€/mois** (alternative moins chère mais moins performante)
- LoadBalancer public : **~1-2€/mois**
- Bande passante sortante : **~1€/mois** (pour usage test)

**Total estimé : 12-33€/mois** selon votre choix de VM

> 💡 **Astuce** : Arrêtez le cluster quand vous ne l'utilisez pas pour économiser (conserve l'infra, coût réduit).

## 📋 Prérequis

### Outils nécessaires

```bash
# Azure CLI
brew install azure-cli

# Terraform
brew install terraform

# kubectl (si pas déjà installé)
brew install kubectl

# Helm (si pas déjà installé)
brew install helm
```

### Compte Azure

1. Créez un compte Azure : https://azure.microsoft.com/free/
2. Obtenez 200$ de crédit gratuit pour les nouveaux comptes
3. Connectez-vous :

```bash
az login
```

### GitHub Container Registry

Vous allez builder vos images Docker localement et les pousser sur GHCR.

Créez un Personal Access Token (PAT) sur GitHub :
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)

## 📝 Workflow de Développement

### 🆕 Premier déploiement
```bash
# 1. Configurer .env avec vos credentials
cp .env.example .env
# Éditer .env avec vos valeurs

# 2. Builder et pousser les images (AVEC --no-cache)
./build-and-push-azure.sh

# 3. Déployer sur Azure
./azure-deploy.sh
```

### 🔄 Après modification du code

```bash
# 1. Rebuilder et pousser (--no-cache est automatique maintenant)
./build-and-push-azure.sh

# 2. Recharger les images sur AKS (méthode sécurisée)
./azure-reload-images.sh

# 3. Vérifier le statut
./azure-status.sh
```

### ⚠️ Important: Problème de cache Docker Buildx

**Symptôme**: Vous modifiez le code, vous lancez `build-and-push-azure.sh`, mais les changements n'apparaissent pas sur Azure.

**Cause**: Docker buildx peut utiliser son cache même avec les nouvelles modifications.

**Solution**: Le script `build-and-push-azure.sh` utilise maintenant automatiquement `--no-cache` pour forcer un rebuild complet à chaque fois.

### ⚠️ Important: Rollout restart sur petits clusters

**Pourquoi pas de rollout restart automatique?**

Le script `azure-deploy.sh` ne fait plus de `kubectl rollout restart` car:
- Sur petits clusters (Standard_B2s = 2 vCPU), le rollout peut échouer avec `Insufficient CPU`
- Kubernetes essaie de créer un nouveau pod **avant** de supprimer l'ancien
- Avec 7 services, on atteint facilement 100% CPU utilisé

**Solution recommandée**:
```bash
./azure-reload-images.sh  # Supprime puis recrée les pods un par un
```
2. Créez un token avec les scopes `read:packages` et `write:packages`
3. Sauvegardez le token en lieu sûr

## 🚀 Configuration initiale

### 1. Build et push des images Docker

**Option automatique (recommandée)** :

Créez votre fichier de configuration :

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Éditez `terraform/terraform.tfvars` :

```hcl
# Configuration de base
resource_group_name = "rg-hello-world"
location            = "francecentral"  # ou westeurope, northeurope
cluster_name        = "aks-hello-world"

# Configuration des nodes (choisissez selon votre budget)
node_count   = 1              # 1 node suffisant pour les tests
node_vm_size = "Standard_B2s" # ou "Standard_B1s" pour économiser

# Version Kubernetes
kubernetes_version = "1.29"

# GitHub Container Registry (utilisez les mêmes credentials que pour le build)
ghcr_username = "votre-username-github"
ghcr_token    = "ghp_votre_token_ici"
```

### 3. Configuration Helm
### 2. Configuration Terraform

Créez votre fichier de configuration :

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Éditez `terraform/terraform.tfvars` :

```hcl
# Configuration de base
resource_group_name = "rg-hello-world"
location            = "francecentral"  # ou westeurope, northeurope
cluster_name        = "aks-hello-world"

# Configuration des nodes (choisissez selon votre budget)
node_count   = 1              # 1 node suffisant pour les tests
node_vm_size = "Standard_B2s" # ou "Standard_B1s" pour économiser

# Version Kubernetes
kubernetes_version = "1.29"

# GitHub Container Registry
ghcr_username = "votre-username-github"
ghcr_token    = "ghp_votre_token_ici"
```

### 2. Configuration Helm

Éditez `helm/values-azure.yaml` et remplacez `your-github-username` par votre username GitHub :

```yaml
backend:
  image:
    repository: ghcr.io/VOTRE-USERNAME/hello-backend
    
frontend:
  image:
    repository: ghcr.io/VOTRE-USERNAME/hello-frontend
```

## 🏗️ Déploiement

### Workflow complet (recommandé)

```bash
./azure-deploy.sh
```

Ce script va :
1. ❓ Vous demander si vous voulez builder/pousser les images (si pas déjà fait)
2. ✅ Vérifier tous les prérequis
3. 🏗️ Créer l'infrastructure Azure avec Terraform (AKS, resource group, etc.)
4. 🔑 Configurer kubectl pour accéder au cluster
5. 📦 Déployer l'application avec Helm
6. ⏳ Attendre que tous les pods soient prêts
7. 📊 Afficher le statut du déploiement

```bash
./azure-deploy.sh
```

Ce script va :
1. ✅ Vérifier tous les prérequis
2. 🏗️ Créer l'infrastructure Azure avec Terraform (AKS, resource group, etc.)
3. 🔑 Configurer kubectl pour accéder au cluster
4. 📦 Déployer l'application avec Helm
5. ⏳ Attendre que tous les pods soient prêts
6. 📊 Afficher le statut du déploiement

**Durée estimée** : 10-15 minutes (création du cluster AKS)

### Déploiement manuel (étape par étape)

Si vous préférez contrôler chaque étape :

#### Étape 1 : Infrastructure Terraform

```bash
cd terraform

# Initialisation
terraform init

# Planification
terraform plan

# Application
terraform apply
```

#### Étape 2 : Configuration kubectl

```bash
# Récupérer les credentials
az aks get-credentials --resource-group rg-hello-world --name aks-hello-world

# Vérifier la connexion
kubectl cluster-info
kubectl get nodes
```

#### Étape 3 : Déploiement Helm

```bash
cd ..

# Installation
helm install hello-world ./helm -f ./helm/values-azure.yaml

# Ou mise à jour si déjà installé
helm upgrade hello-world ./helm -f ./helm/values-azure.yaml
```

## 🌐 Accès à l'application

### Récupérer l'IP publique

```bash
kubectl get service hello-world-frontend-service
```

Attendez que la colonne `EXTERNAL-IP` affiche une IP (peut prendre 2-3 minutes) :

```
NAME                            TYPE           EXTERNAL-IP     PORT(S)
hello-world-frontend-service    LoadBalancer   20.74.xxx.xxx   80:xxxxx/TCP
```

Ouvrez votre navigateur : `http://20.74.xxx.xxx`

### Surveiller l'attribution de l'IP

```bash
kubectl get service hello-world-frontend-service --watch
```

## 📊 Monitoring et maintenance

### Vérifier le statut

```bash
./azure-status.sh
```

### Voir les logs

```bash
# Backend
kubectl logs -f -l app=hello-world-backend

# Frontend
kubectl logs -f -l app=hello-world-frontend

# Logs d'un pod spécifique
kubectl logs -f <pod-name>
```

### Redémarrer l'application

```bash
kubectl rollout restart deployment/hello-world-backend
kubectl rollout restart deployment/hello-world-frontend
```

### Mettre à jour les images

Après avoir modifié votre code :

```bash
# 1. Rebuilder et pousser les nouvelles images
./build-and-push-azure.sh

# 2. Redémarrer les pods pour pull les nouvelles images
kubectl rollout restart deployment/hello-world-backend
kubectl rollout restart deployment/hello-world-frontend
```m upgrade hello-world ./helm -f ./helm/values-azure.yaml \
  --set backend.replicaCount=2 \
  --set frontend.replicaCount=2
```

### Mettre à jour les images

Après avoir poussé de nouvelles images sur GHCR :

```bash
# Forcer le redémarrage pour pull les nouvelles images
kubectl rollout restart deployment/hello-world-backend
kubectl rollout restart deployment/hello-world-frontend
```

## 🔧 Gestion des coûts

### Arrêter le cluster (économiser des coûts)

```bash
# Arrêter le cluster (conserve la configuration)
az aks stop --resource-group rg-hello-world --name aks-hello-world
```

Le cluster arrêté ne facture que le stockage (~1-2€/mois). Redémarrez-le quand nécessaire :

```bash
# Redémarrer le cluster
az aks start --resource-group rg-hello-world --name aks-hello-world
```

### Réduire les coûts au minimum

1. **Utilisez 1 seul node** : `node_count = 1` dans terraform.tfvars
2. **VM économique** : `node_vm_size = "Standard_B1s"` (~10€/mois)
3. **Arrêtez le cluster** quand vous ne l'utilisez pas
4. **Supprimez complètement** si vous ne l'utilisez pas pendant longtemps

### Surveiller les coûts

```bash
# Voir les ressources de votre resource group
az resource list --resource-group rg-hello-world --output table

# Vérifier la consommation (via le portail Azure)
# https://portal.azure.com/ → Cost Management + Billing
```

## 🧹 Nettoyage

### Suppression complète

```bash
./azure-cleanup.sh
```

Ce script va :
1. 🗑️ Désinstaller le release Helm
2. 🗑️ Détruire l'infrastructure Terraform
3. 🗑️ Supprimer le resource group et toutes les ressources

**Confirmez sur le portail Azure** que tout est bien supprimé :
https://portal.azure.com/ → Resource groups

### Nettoyage manuel

```bash
# Désinstaller Helm
helm uninstall hello-world

# Détruire l'infrastructure
cd terraform
terraform destroy
```

## 🐛 Dépannage

### Les pods ne démarrent pas

```bash
# Voir les détails du pod
kubectl describe pod <pod-name>

# Vérifier les logs
kubectl logs <pod-name>

# Vérifier les events
kubectl get events --sort-by='.lastTimestamp'
```

### Erreur "ImagePullBackOff"

Vérifiez que :
1. Vos images sont bien sur GHCR : `ghcr.io/votre-username/...`
2. Le secret `ghcr-secret` existe : `kubectl get secret ghcr-secret`
3. Votre PAT GitHub a le scope `read:packages`
4. Les noms d'images dans `values-azure.yaml` sont corrects

Recréez le secret si nécessaire :

```bash
kubectl delete secret ghcr-secret
cd terraform
terraform apply -auto-approve
```

### LoadBalancer sans IP externe

```bash
# Vérifier les events du service
kubectl describe service hello-world-frontend-service

# Attendre quelques minutes
kubectl get service hello-world-frontend-service --watch
```

Si l'IP n'arrive pas après 5 minutes, vérifiez vos quotas Azure.

### Erreur Terraform "quota exceeded"

Certaines régions ont des quotas limités. Solutions :
1. Changez de région dans `terraform.tfvars` : `location = "westeurope"`
2. Demandez une augmentation de quota (portail Azure)
3. Utilisez un node_count plus petit

### Connexion kubectl perdue

```bash
# Récupérer à nouveau les credentials
az aks get-credentials --resource-group rg-hello-world --name aks-hello-world --overwrite-existing

# Vérifier la connexion
kubectl cluster-info
```

## 📚 Commandes utiles

### Azure CLI

```bash
# Lister les clusters AKS
az aks list --output table

# Voir les détails d'un cluster
az aks show --resource-group rg-hello-world --name aks-hello-world

# Lister les resource groups
az group list --output table

# Supprimer un resource group (et tout son contenu)
az group delete --name rg-hello-world --yes --no-wait
```

### kubectl

```bash
# Contexte actuel
kubectl config current-context

# Lister tous les contextes
kubectl config get-contexts

# Changer de contexte
kubectl config use-context <context-name>

# Voir toutes les ressources
kubectl get all

# Exécuter une commande dans un pod
kubectl exec -it <pod-name> -- /bin/sh
```

### Helm

```bash
# Lister les releases
helm list

# Voir l'historique des releases
helm history hello-world

# Rollback vers une version précédente
helm rollback hello-world <revision>

# Voir les valeurs actuelles
helm get values hello-world
```

## 🔐 Sécurité

### Bonnes pratiques

1. **Ne commitez JAMAIS** `terraform.tfvars` (contient des secrets)
2. **Utilisez des secrets Kubernetes** pour les données sensibles
3. **Limitez les accès** avec RBAC
4. **Mettez à jour régulièrement** Kubernetes et vos dépendances
5. **Surveillez les CVE** de vos images Docker

### Gérer les secrets

Pour ajouter d'autres secrets :

```bash
kubectl create secret generic my-secret \
  --from-literal=username=admin \
  --from-literal=password='S3cr3t!'
```

## 🎯 Prochaines étapes

### Améliorations possibles

1. **CI/CD** : Automatiser avec GitHub Actions
2. **Monitoring** : Ajouter Azure Monitor / Prometheus
3. **Ingress** : Utiliser un Ingress Controller au lieu de LoadBalancer
4. **HTTPS** : Configurer Let's Encrypt avec cert-manager
5. **Base de données** : Ajouter Azure Database for PostgreSQL
6. **Cache** : Ajouter Azure Cache for Redis
7. **Autoscaling** : Configurer HPA (Horizontal Pod Autoscaler)
8. **Backup** : Configurer Azure Backup pour AKS

## 📖 Ressources
## ⚡ Quick Start TL;DR

```bash
# 1. Build et push des images
./build-and-push-azure.sh
# Entrez votre username GitHub et PAT

# 2. Configuration Terraform
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Éditez terraform/terraform.tfvars avec vos valeurs

# 3. Déploiement
az login
./azure-deploy.sh

# 4. Accès
kubectl get service hello-world-frontend-service
# Ouvrez http://<EXTERNAL-IP>

# 5. Nettoyage
./azure-cleanup.sh
```
```bash
# 1. Configuration
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Éditez terraform/terraform.tfvars avec vos valeurs

# 2. Déploiement
az login
./azure-deploy.sh

# 3. Accès
kubectl get service hello-world-frontend-service
# Ouvrez http://<EXTERNAL-IP>

# 4. Nettoyage
./azure-cleanup.sh
```
