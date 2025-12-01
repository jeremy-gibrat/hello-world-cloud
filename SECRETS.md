# Gestion des Secrets

## 📋 Vue d'ensemble

Les secrets de l'application (mots de passe, tokens) sont maintenant gérés de manière sécurisée via :
1. **Fichier `.env`** (local, non commité dans git)
2. **Kubernetes Secrets** (créés automatiquement depuis `.env`)
3. **Helm templates** (référencent les secrets Kubernetes)

## 🔐 Configuration

### 1. Créer votre fichier `.env`

```bash
cp .env.example .env
```

### 2. Éditer `.env` avec vos secrets

```bash
# Application Secrets
POSTGRES_DB="hellodb"
POSTGRES_USER="hellouser"
POSTGRES_PASSWORD="votre_mot_de_passe_securise"
RABBITMQ_USER="admin"
RABBITMQ_PASSWORD="votre_mot_de_passe_rabbitmq"
```

**⚠️ Important :** 
- Ne JAMAIS commiter le fichier `.env` dans git
- Utiliser des mots de passe forts en production
- Le fichier `.env` est déjà dans `.gitignore`

### 3. Les secrets sont créés automatiquement

Les scripts `deploy.sh` et `azure-deploy.sh` créent automatiquement les secrets Kubernetes depuis `.env`.

Si vous devez créer/mettre à jour les secrets manuellement :

```bash
./create-secrets.sh
```

## 🔍 Vérification des secrets

```bash
# Lister les secrets
kubectl get secrets

# Voir le secret app-secrets
kubectl describe secret app-secrets

# Décoder un secret (pour debug)
kubectl get secret app-secrets -o jsonpath='{.data.postgres-user}' | base64 -d
```

## 🏗️ Architecture

### Flux de données

```
.env (local)
    ↓
create-secrets.sh
    ↓
Kubernetes Secret (app-secrets)
    ↓
Helm Templates
    ↓
Pods (PostgreSQL, RabbitMQ, Backend)
```

### Secrets créés

Le secret `app-secrets` contient :
- `postgres-db` : Nom de la base de données
- `postgres-user` : Utilisateur PostgreSQL
- `postgres-password` : Mot de passe PostgreSQL
- `rabbitmq-user` : Utilisateur RabbitMQ
- `rabbitmq-password` : Mot de passe RabbitMQ

### Utilisation dans les pods

**PostgreSQL :**
```yaml
env:
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: app-secrets
        key: postgres-password
```

**Backend :**
```yaml
env:
  - name: SPRING_DATASOURCE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: app-secrets
        key: postgres-password
```

## 🚀 Déploiement

### Local (Minikube)

```bash
# Les secrets sont créés automatiquement
./deploy.sh
```

### Azure AKS

```bash
# Les secrets sont créés automatiquement
./azure-deploy.sh
```

## 🔄 Mise à jour des secrets

Si vous modifiez les secrets dans `.env` :

```bash
# Recréer les secrets
./create-secrets.sh

# Redémarrer les pods pour utiliser les nouveaux secrets
kubectl rollout restart deployment/postgres
kubectl rollout restart deployment/rabbitmq
kubectl rollout restart deployment/hello-world-backend
```

## 🛡️ Bonnes pratiques

### ✅ À faire

- Utiliser des mots de passe forts et uniques
- Changer les mots de passe par défaut
- Utiliser un gestionnaire de secrets (ex: 1Password, Bitwarden) pour stocker `.env`
- Documenter les secrets requis dans `.env.example`
- Utiliser des secrets différents par environnement (dev/staging/prod)

### ❌ À éviter

- Commiter `.env` dans git
- Utiliser les mêmes mots de passe partout
- Partager `.env` par email ou chat
- Hardcoder les secrets dans le code
- Logger les secrets

## 🔐 Production : Azure Key Vault

Pour la production, il est recommandé d'utiliser Azure Key Vault au lieu de fichiers `.env` :

### 1. Créer un Key Vault

```bash
az keyvault create \
  --name kv-hello-world \
  --resource-group rg-hello-world \
  --location francecentral
```

### 2. Ajouter les secrets

```bash
az keyvault secret set --vault-name kv-hello-world \
  --name postgres-password --value "votre_mot_de_passe"

az keyvault secret set --vault-name kv-hello-world \
  --name rabbitmq-password --value "votre_mot_de_passe"
```

### 3. Configurer AKS pour utiliser Key Vault

Utiliser le [Azure Key Vault Provider for Secrets Store CSI Driver](https://docs.microsoft.com/en-us/azure/aks/csi-secrets-store-driver) :

```bash
az aks enable-addons \
  --addons azure-keyvault-secrets-provider \
  --name aks-hello-world \
  --resource-group rg-hello-world
```

### 4. Créer un SecretProviderClass

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: app-secrets-provider
spec:
  provider: azure
  parameters:
    keyvaultName: "kv-hello-world"
    objects: |
      array:
        - objectName: "postgres-password"
          objectType: "secret"
        - objectName: "rabbitmq-password"
          objectType: "secret"
```

## 📚 Références

- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/)
- [Helm Secrets](https://helm.sh/docs/chart_best_practices/secrets/)
- [12-Factor App: Config](https://12factor.net/config)

## 🆘 Dépannage

### Secret non trouvé

```bash
# Vérifier que le secret existe
kubectl get secret app-secrets

# Si absent, le créer
./create-secrets.sh
```

### Pod en erreur avec "secret not found"

```bash
# Le secret doit exister AVANT le déploiement Helm
./create-secrets.sh
helm upgrade --install hello-world ./helm
```

### Mauvais mot de passe

```bash
# Mettre à jour .env
nano .env

# Recréer le secret
./create-secrets.sh

# Redémarrer les pods
kubectl delete pod -l app=postgres
kubectl delete pod -l app=rabbitmq
kubectl delete pod -l app=hello-world-backend
```
