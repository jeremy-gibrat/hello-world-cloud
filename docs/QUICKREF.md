# 🚀 Quick Reference - Commandes Essentielles

Guide de référence rapide pour les opérations courantes.

## 📦 Développement Local (Minikube)

### Démarrage Initial
```bash
minikube start --cpus=4 --memory=8192
./build-images.sh
./deploy.sh
minikube service hello-world-frontend-service
```

### Après Modification du Code
```bash
./build-images.sh                                # Rebuild avec --no-cache
kubectl rollout restart deployment/hello-world-backend
kubectl rollout restart deployment/hello-world-frontend
```

### Tunnels pour Accès Local
```bash
./tunnel.sh                                      # Démarre tous les tunnels
# Frontend: http://localhost:3000
# Backend:  http://localhost:8081
# Kibana:   http://localhost:5601
# RabbitMQ: http://localhost:15672
# PostgreSQL: localhost:5432
```

### Nettoyage
```bash
./cleanup.sh                                     # Désinstalle l'application
minikube stop                                    # Arrête le cluster
minikube delete                                  # Supprime complètement
```

---

## ☁️ Production Azure (AKS)

### Déploiement Initial
```bash
cp .env.example .env                             # Configurer credentials
./build-and-push-azure.sh                        # Build + push GHCR
./azure-deploy.sh                                # Déployer sur Azure
```

### Après Modification du Code
```bash
./build-and-push-azure.sh                        # Rebuild avec --no-cache
./azure-reload-images.sh                         # Recharge les images (menu)
./azure-status.sh                                # Vérifie le statut
```

### Obtenir l'IP Publique
```bash
kubectl get service hello-world-frontend-service
# Ouvrir http://<EXTERNAL-IP>
```

### Nettoyage
```bash
./azure-cleanup.sh                               # Supprime tout sur Azure
```

---

## 🔍 Diagnostic et Debug

### État des Pods
```bash
kubectl get pods                                 # État de tous les pods
kubectl get pods -w                              # Watch mode (temps réel)
kubectl describe pod <pod-name>                  # Détails d'un pod
```

### Logs
```bash
kubectl logs deployment/hello-world-backend      # Logs backend
kubectl logs -f deployment/hello-world-backend   # Logs en temps réel
kubectl logs deployment/postgres                 # Logs PostgreSQL
kubectl logs --previous <pod-name>               # Logs du pod précédent (crash)
```

### Ressources
```bash
kubectl top nodes                                # CPU/RAM par node
kubectl top pods                                 # CPU/RAM par pod
kubectl describe nodes | grep -A 5 "Allocated"  # Ressources allouées
```

### Tests d'API depuis les Pods
```bash
# Backend health check
kubectl exec deployment/hello-world-backend -- curl http://localhost:8080/api/hello

# PostgreSQL users count
kubectl exec deployment/hello-world-backend -- curl http://localhost:8080/api/users/count

# PostgreSQL users list
kubectl exec deployment/hello-world-backend -- curl http://localhost:8080/api/users

# PostgreSQL database version
kubectl exec deployment/postgres -- psql -U hellouser -d hellodb -c "SELECT version();"

# Elasticsearch health
kubectl exec deployment/hello-world-backend -- curl http://elasticsearch:9200/_cluster/health
```

### Port-Forward Manuel
```bash
kubectl port-forward deployment/hello-world-backend 8080:8080
kubectl port-forward deployment/hello-world-frontend 3000:80
kubectl port-forward deployment/postgres 5432:5432
kubectl port-forward deployment/rabbitmq 15672:15672
kubectl port-forward deployment/kibana 5601:5601
```

---

## 🔄 Gestion des Déploiements

### Redémarrer un Service
```bash
kubectl rollout restart deployment/hello-world-backend
kubectl rollout restart deployment/hello-world-frontend
kubectl rollout restart deployment/postgres
```

### Vérifier le Rollout
```bash
kubectl rollout status deployment/hello-world-backend
kubectl rollout history deployment/hello-world-backend
```

### Revenir en Arrière (Rollback)
```bash
kubectl rollout undo deployment/hello-world-backend
kubectl rollout undo deployment/hello-world-backend --to-revision=2
```

### Scaler un Service
```bash
kubectl scale deployment/hello-world-backend --replicas=2
kubectl scale deployment/logstash --replicas=0        # Désactiver
```

---

## 🐘 PostgreSQL

### Accès Direct
```bash
# Via port-forward
kubectl port-forward deployment/postgres 5432:5432
psql -h localhost -U hellouser -d hellodb

# Via exec
kubectl exec -it deployment/postgres -- psql -U hellouser -d hellodb
```

### Requêtes SQL Rapides
```bash
# Compter les utilisateurs
kubectl exec deployment/postgres -- psql -U hellouser -d hellodb -c "SELECT COUNT(*) FROM users;"

# Lister les utilisateurs
kubectl exec deployment/postgres -- psql -U hellouser -d hellodb -c "SELECT * FROM users;"

# Ajouter un utilisateur
kubectl exec deployment/postgres -- psql -U hellouser -d hellodb -c "INSERT INTO users (name, email) VALUES ('Test User', 'test@example.com');"
```

### Initialiser les Données via API
```bash
kubectl exec deployment/hello-world-backend -- curl -X POST http://localhost:8080/api/users/init
```

---

## 🐰 RabbitMQ

### Accès Management UI
```bash
# Minikube
./tunnel.sh
# Puis ouvrir http://localhost:15672
# Identifiants: guest / guest

# Azure avec port-forward
kubectl port-forward deployment/rabbitmq 15672:15672
```

### Envoyer un Message via API
```bash
kubectl exec deployment/hello-world-backend -- curl -X POST \
  http://localhost:8080/api/send \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from CLI"}'
```

### Recevoir les Messages
```bash
kubectl exec deployment/hello-world-backend -- curl http://localhost:8080/api/messages
```

---

## 📊 Elasticsearch & Kibana

### Accès Kibana
```bash
# Minikube
./tunnel.sh
# Puis ouvrir http://localhost:5601

# Azure avec port-forward
kubectl port-forward deployment/kibana 5601:5601
```

### Requêtes Elasticsearch
```bash
# Santé du cluster
kubectl exec deployment/elasticsearch -- curl http://localhost:9200/_cluster/health

# Lister les indices
kubectl exec deployment/elasticsearch -- curl http://localhost:9200/_cat/indices

# Compter les documents
kubectl exec deployment/elasticsearch -- curl http://localhost:9200/logs/_count
```

### Indexer via API Backend
```bash
kubectl exec deployment/hello-world-backend -- curl -X POST \
  http://localhost:8080/api/search/index \
  -H "Content-Type: application/json" \
  -d '{"message": "Test log entry"}'
```

---

## 🔧 Helm

### Lister les Releases
```bash
helm list
helm list --all-namespaces
```

### Upgrade avec Nouvelles Values
```bash
helm upgrade hello-world ./helm -f ./helm/values.yaml
helm upgrade hello-world ./helm -f ./helm/values-azure.yaml
```

### Désinstaller
```bash
helm uninstall hello-world
```

### Voir les Valeurs Actuelles
```bash
helm get values hello-world
```

---

## 🌐 Contextes kubectl

### Lister les Contextes
```bash
kubectl config get-contexts
```

### Changer de Contexte
```bash
kubectl config use-context minikube
kubectl config use-context <aks-cluster-name>
```

### Contexte Actuel
```bash
kubectl config current-context
```

---

## 🚨 Urgences

### Tout Redémarrer
```bash
kubectl rollout restart deployment --all
```

### Supprimer un Pod Bloqué
```bash
kubectl delete pod <pod-name> --grace-period=0 --force
```

### Nettoyer les Pods Failed
```bash
kubectl delete pods --field-selector status.phase=Failed
```

### Voir les Événements Récents
```bash
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

### Vérifier les Images
```bash
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
```

---

## 📖 Documentation Complète

- **Problèmes de cache?** → [PREVENTION.md](PREVENTION.md)
- **Erreurs de déploiement?** → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Configuration Azure?** → [AZURE.md](AZURE.md)
- **API PostgreSQL?** → [POSTGRESQL.md](POSTGRESQL.md)

---

## 💡 Alias Utiles

Ajoutez à votre `~/.zshrc`:
```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgd='kubectl get deployments'
alias kgs='kubectl get services'
alias kl='kubectl logs'
alias kd='kubectl describe'
alias ke='kubectl exec -it'
alias kr='kubectl rollout restart'
alias kw='kubectl wait --for=condition=ready'
```

Puis: `source ~/.zshrc`
