# Documentation - Hello World Kubernetes

Bienvenue dans la documentation complète du projet Hello World Kubernetes.

## 📚 Table des Matières

### 🚀 Démarrage

- [**QUICKREF.md**](QUICKREF.md) - Référence rapide des commandes
  - Commandes essentielles pour démarrer rapidement
  - Cheat sheet pratique

### 🏗️ Architecture & Déploiement

- [**SCRIPTS.md**](SCRIPTS.md) - Documentation des scripts et Makefile
  - Structure des scripts
  - Utilisation du Makefile
  - Fonctions disponibles
  - Exemples d'utilisation

- [**AZURE.md**](AZURE.md) - Guide Azure AKS avec Terraform
  - Configuration Azure
  - Déploiement AKS
  - Gestion de l'infrastructure
  - Optimisation des coûts

### 🔐 Sécurité & Configuration

- [**SECRETS.md**](SECRETS.md) - Gestion des secrets et mots de passe
  - Configuration du fichier `.env`
  - Kubernetes Secrets
  - Azure Key Vault
  - Bonnes pratiques de sécurité

### 🗄️ Base de Données

- [**POSTGRESQL.md**](POSTGRESQL.md) - Documentation PostgreSQL
  - Configuration de la base de données
  - API Users
  - Migration et backup
  - Troubleshooting

### 🛠️ Maintenance & Dépannage

- [**TROUBLESHOOTING.md**](TROUBLESHOOTING.md) - Résolution des problèmes
  - Problèmes courants et solutions
  - Guide de diagnostic
  - Commandes de debug

- [**PREVENTION.md**](PREVENTION.md) - Prévention des problèmes
  - Éviter les problèmes de cache Docker
  - Bonnes pratiques
  - Checklist avant déploiement

### 🔄 Migration

- [**MIGRATION.md**](MIGRATION.md) - Migration vers nouvelle architecture
  - Guide de migration depuis l'ancienne structure
  - Correspondance des commandes
  - Nouvelles fonctionnalités

## 🎯 Par Cas d'Usage

### Je débute avec le projet
1. Commencez par [QUICKREF.md](QUICKREF.md)
2. Suivez les instructions du [README principal](../README.md)
3. Consultez [SCRIPTS.md](SCRIPTS.md) pour comprendre l'organisation

### Je veux déployer sur Azure
1. Lisez [AZURE.md](AZURE.md)
2. Configurez vos secrets avec [SECRETS.md](SECRETS.md)
3. Utilisez `make help` pour les commandes

### J'ai un problème
1. Consultez [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Vérifiez [PREVENTION.md](PREVENTION.md)
3. Utilisez `make status` et `make events`

### Je configure la base de données
1. Suivez [POSTGRESQL.md](POSTGRESQL.md)
2. Configurez les secrets dans [SECRETS.md](SECRETS.md)

### Je migre depuis l'ancienne structure
1. Lisez [MIGRATION.md](MIGRATION.md)
2. Consultez [SCRIPTS.md](SCRIPTS.md) pour les nouvelles commandes

## 🔍 Recherche Rapide

- **Commandes** → [QUICKREF.md](QUICKREF.md) ou `make help`
- **Scripts** → [SCRIPTS.md](SCRIPTS.md)
- **Secrets** → [SECRETS.md](SECRETS.md)
- **Azure** → [AZURE.md](AZURE.md)
- **Erreurs** → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **PostgreSQL** → [POSTGRESQL.md](POSTGRESQL.md)

## 💡 Conseils

- Utilisez `make help` pour voir toutes les commandes disponibles
- Le mode debug est activable avec `DEBUG=true make <commande>`
- Les logs sont accessibles via `make logs-<service>`
- La documentation est mise à jour régulièrement

## 🆘 Support

Si vous ne trouvez pas ce que vous cherchez :
1. Consultez `make help`
2. Vérifiez le [README principal](../README.md)
3. Parcourez les fichiers de cette documentation

---

[← Retour au README principal](../README.md)
