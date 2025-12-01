# Migration vers la nouvelle architecture

## 📋 Changements

### Ancienne structure (12 scripts à la racine)
```
hello-world/
├── build-images.sh
├── deploy.sh
├── cleanup.sh
├── status.sh
├── tunnel.sh
├── azure-deploy.sh
├── azure-cleanup.sh
├── azure-status.sh
├── azure-reload-images.sh
├── build-and-push-azure.sh
├── create-secrets.sh
└── terraform/generate-tfvars.sh
```

### Nouvelle structure (organisée + Makefile)
```
hello-world/
├── Makefile                  # Interface unifiée
├── scripts/
│   ├── lib/                 # Fonctions partagées
│   │   ├── common.sh       # Logging, vérifications
│   │   ├── k8s.sh          # Kubernetes
│   │   └── docker.sh       # Docker
│   ├── local/              # Scripts Minikube
│   │   ├── build.sh
│   │   ├── deploy.sh
│   │   └── cleanup.sh
│   ├── azure/              # Scripts Azure
│   │   ├── build.sh
│   │   ├── deploy.sh
│   │   └── cleanup.sh
│   └── utils/              # Utilitaires
│       ├── secrets.sh
│       ├── status.sh
│       └── tunnel.sh
└── terraform/
    └── generate-tfvars.sh
```

## 🔄 Table de correspondance

| Ancien Script | Nouvelle Commande | Description |
|--------------|-------------------|-------------|
| `./build-images.sh` | `make build-local` | Build local |
| `./deploy.sh` | `make deploy-local` | Deploy local |
| `./cleanup.sh` | `make clean-local` | Cleanup local |
| `./status.sh` | `make status` | État du cluster |
| `./tunnel.sh` | `make tunnel` | Tunnels SSH |
| `./build-and-push-azure.sh` | `make build-azure` | Build Azure |
| `./azure-deploy.sh` | `make deploy-azure` | Deploy Azure |
| `./azure-cleanup.sh` | `make clean-azure` | Cleanup Azure |
| `./azure-status.sh` | `make status` | État (même commande) |
| `./azure-reload-images.sh` | `make build-azure && make restart-all` | Rebuild + restart |
| `./create-secrets.sh` | `make secrets` | Créer secrets |

## ✨ Nouvelles fonctionnalités

### Commandes simplifiées
```bash
make full-local   # Build + Deploy local en une commande
make full-azure   # Build + Deploy Azure en une commande
make help         # Aide interactive avec toutes les commandes
```

### Fonctions réutilisables
```bash
# Logging avec couleurs
log_info "Message"
log_success "✓ Succès"
log_error "✗ Erreur"

# Vérifications automatiques
check_prerequisites docker kubectl helm
ensure_minikube_context
ensure_aks_context "cluster-name"

# Gestion d'erreur intégrée
set -euo pipefail  # Dans tous les scripts
```

### Auto-détection
```bash
make clean  # Détecte automatiquement Minikube ou Azure
```

### Logs et Debug
```bash
make logs-backend       # Logs backend
make logs-frontend      # Logs frontend
make debug-backend      # Shell dans le pod
make describe-backend   # Détails du pod
make events             # Événements K8s
```

### Maintenance
```bash
make restart-backend           # Redémarre le backend
make restart-all               # Redémarre tout
make scale-backend REPLICAS=3  # Scale le backend
```

### CI/CD
```bash
make ci-test    # Tests pour CI
make ci-build   # Build pour CI
make ci-deploy  # Deploy pour CI
```

## 🚀 Avantages

### ✅ Organisation
- Code réutilisable dans `scripts/lib/`
- Séparation claire local/azure
- Un seul point d'entrée (Makefile)

### ✅ Maintenabilité
- Moins de duplication de code
- Fonctions testables isolément
- Gestion d'erreur cohérente

### ✅ Utilisabilité
- Interface unifiée avec `make`
- Auto-complétion des commandes
- Aide intégrée (`make help`)

### ✅ Robustesse
- Vérifications automatiques des prérequis
- Gestion d'erreur avec `set -euo pipefail`
- Logging clair avec couleurs

### ✅ Flexibilité
- Variables d'environnement via `.env`
- Mode debug avec `DEBUG=true`
- Paramètres personnalisables

## 📝 Migration pas à pas

### Option 1 : Immédiate (Recommandé)
```bash
# Les anciens scripts peuvent être supprimés
rm build-images.sh deploy.sh cleanup.sh status.sh tunnel.sh
rm azure-*.sh build-and-push-azure.sh create-secrets.sh

# Utilisez le Makefile à la place
make help
```

### Option 2 : Progressive
Gardez les anciens scripts comme wrappers :
```bash
# Exemple: build-images.sh
#!/bin/bash
make build-local
```

### Option 3 : Cohabitation
Les deux systèmes peuvent coexister temporairement.

## 📚 Documentation

- [SCRIPTS.md](SCRIPTS.md) - Documentation complète des scripts
- [README.md](README.md) - Guide d'utilisation mis à jour
- `make help` - Aide interactive

## 💡 Conseils

1. **Utilisez `make help`** pour découvrir toutes les commandes
2. **Activez l'auto-complétion** : `complete -W "$(make -qp | awk -F':' '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$)/ {split($1,A,/ /);for(i in A)print A[i]}' | sort -u)" make`
3. **Mode debug** : `DEBUG=true make deploy-local`
4. **Explorez les scripts** dans `scripts/lib/` pour comprendre le fonctionnement

## ⚠️ Breaking Changes

Aucun ! Les anciens scripts peuvent continuer à fonctionner si vous ne les supprimez pas.

## 🆘 Support

En cas de problème :
1. Consultez `make help`
2. Lisez [SCRIPTS.md](SCRIPTS.md)
3. Vérifiez [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
