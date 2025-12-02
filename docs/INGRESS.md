# 🌐 Exposition Publique du Frontend

## Vue d'ensemble

Ce projet supporte maintenant l'exposition publique du frontend via **Kubernetes Ingress**, permettant un accès via une URL publique au lieu de tunnels SSH.

## 🎯 Architectures Supportées

### **Minikube (Développement)**
- **Type** : NodePort (port 30080)
- **Accès** : `minikube service hello-world-frontend-service`
- **Ingress** : Optionnel (désactivé par défaut)

### **Azure AKS (Production)**
- **Type** : Ingress avec Azure Application Routing ou NGINX
- **Accès** : Via domaine public (ex: `hello-world.example.com`)
- **Coût** : Gratuit (pas de LoadBalancer nécessaire)

---

## 🚀 Déploiement Azure avec Ingress

### **Étape 1 : Configuration de l'Ingress**

```bash
# Lancer le script de configuration
make setup-ingress
```

Le script vous guidera pour :
1. Choisir le type d'Ingress Controller
2. Configurer votre domaine
3. (Optionnel) Activer SSL/TLS avec Let's Encrypt

### **Étape 2 : Déployer l'application**

```bash
make deploy-azure
```

### **Étape 3 : Obtenir l'IP publique**

```bash
kubectl get ingress hello-world-ingress
```

Sortie :
```
NAME                  CLASS         HOSTS                      ADDRESS        PORTS
hello-world-ingress   nginx         hello-world.example.com    20.123.45.67   80
```

### **Étape 4 : Configurer le DNS**

Dans votre fournisseur DNS (Cloudflare, GoDaddy, etc.), créez un enregistrement A :

```
Type: A
Name: hello-world (ou @)
Value: 20.123.45.67  (l'IP de l'Ingress)
TTL: 300
```

### **Étape 5 : Accéder à l'application**

```bash
# HTTP
http://hello-world.example.com

# HTTPS (si SSL activé)
https://hello-world.example.com
```

---

## 🔧 Types d'Ingress Controllers

### **1. Azure Application Routing (Recommandé)**

✅ **Avantages :**
- Gratuit et intégré à AKS
- Configuration simple
- Maintenance automatique
- Bonne pour petits/moyens projets

❌ **Inconvénients :**
- Moins de fonctionnalités avancées
- Spécifique à Azure

**Configuration :**
```yaml
ingress:
  enabled: true
  className: "webapprouting.kubernetes.azure.com"
```

### **2. NGINX Ingress Controller**

✅ **Avantages :**
- Standard Kubernetes
- Très flexible
- Fonctionnalités avancées (rate limiting, auth, etc.)
- Portable (fonctionne partout)

❌ **Inconvénients :**
- Nécessite installation
- Un peu plus complexe

**Configuration :**
```yaml
ingress:
  enabled: true
  className: "nginx"
```

---

## 🔐 SSL/TLS avec Let's Encrypt

### **Activation automatique**

Le script `setup-ingress.sh` peut activer SSL automatiquement avec cert-manager.

### **Activation manuelle**

1. **Installer cert-manager :**

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

2. **Créer un ClusterIssuer :**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

3. **Activer TLS dans `values-azure.yaml` :**

```yaml
ingress:
  enabled: true
  tls:
    enabled: true
    secretName: hello-world-tls
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

4. **Redéployer :**

```bash
make deploy-azure
```

Le certificat sera automatiquement généré et renouvelé par cert-manager.

---

## 📊 Routes Configurées

L'Ingress expose automatiquement :

| Route | Service | Description |
|-------|---------|-------------|
| `/` | Frontend | Application Angular |
| `/api/*` | Backend | API REST |
| `/actuator/*` | Backend | Health checks & metrics |

**Exemple de requêtes :**
```bash
# Frontend
curl http://hello-world.example.com

# API
curl http://hello-world.example.com/api/hello

# Health check
curl http://hello-world.example.com/actuator/health
```

---

## 🔍 Debugging

### **Vérifier l'Ingress**

```bash
kubectl get ingress hello-world-ingress
kubectl describe ingress hello-world-ingress
```

### **Vérifier les logs NGINX**

```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### **Vérifier cert-manager (si SSL)**

```bash
kubectl get certificate
kubectl describe certificate hello-world-tls
kubectl get certificaterequest
```

### **Test local (avant DNS)**

```bash
# Ajouter à /etc/hosts (temporaire)
echo "20.123.45.67 hello-world.example.com" | sudo tee -a /etc/hosts

# Tester
curl http://hello-world.example.com
```

---

## 💰 Coûts

### **Sans Ingress (Tunnels SSH)**
- ✅ **0€** - Gratuit
- ❌ Pas d'URL publique
- ❌ Nécessite tunnels manuels

### **Avec Ingress**
- ✅ **~0-5€/mois** - IP publique statique (optionnelle)
- ✅ URL publique propre
- ✅ SSL/TLS gratuit
- ✅ Scalable

### **Avec LoadBalancer (non recommandé)**
- ❌ **~25€/mois** - Azure Load Balancer
- Plus cher sans bénéfice pour ce use case

---

## 🎯 Cas d'Usage

### **Utilisez NodePort (Minikube) pour :**
- Développement local
- Tests rapides
- Pas besoin d'accès externe

### **Utilisez Ingress (Azure) pour :**
- **Production** ✅
- **Staging** ✅
- Démonstrations clients
- Partage avec équipe
- Application publique

### **N'utilisez PAS LoadBalancer pour :**
- Ce projet (coût inutile)
- Préférez toujours Ingress

---

## 📝 Configuration Avancée

### **Annotations NGINX utiles**

```yaml
ingress:
  annotations:
    # Rate limiting
    nginx.ingress.kubernetes.io/limit-rps: "10"
    
    # CORS
    nginx.ingress.kubernetes.io/enable-cors: "true"
    
    # Client body size
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    
    # Timeouts
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "30"
```

### **Multiples domaines**

```yaml
ingress:
  hosts:
    - host: hello-world.example.com
    - host: www.hello-world.example.com
    - host: app.example.com
```

### **Redirection HTTP → HTTPS**

```yaml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
```

---

## 🆘 Troubleshooting

### **L'Ingress ne reçoit pas d'IP**

```bash
# Vérifier l'Ingress Controller
kubectl get pods -n ingress-nginx

# Redémarrer si nécessaire
kubectl rollout restart deployment -n ingress-nginx
```

### **502 Bad Gateway**

- Vérifier que les services backend/frontend sont en cours d'exécution
- Vérifier les health checks
- Consulter les logs

### **Certificat SSL ne se génère pas**

```bash
# Vérifier cert-manager
kubectl get pods -n cert-manager

# Vérifier les certificats
kubectl describe certificate hello-world-tls

# Logs cert-manager
kubectl logs -n cert-manager -l app=cert-manager
```

### **DNS ne résout pas**

- Attendre la propagation DNS (jusqu'à 48h)
- Vérifier avec `dig` ou `nslookup`
- Tester avec l'IP directement

---

## 📚 Ressources

- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [cert-manager](https://cert-manager.io/)
- [Azure Application Routing](https://learn.microsoft.com/en-us/azure/aks/app-routing)

---

**Date** : 1 décembre 2025  
**Version** : 1.2.0  
**Statut** : ✅ Production Ready
