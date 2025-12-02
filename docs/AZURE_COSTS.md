# 💰 Analyse des Coûts Azure - Hello World Cloud

Ce document présente une analyse détaillée des coûts liés à l'utilisation des services Azure dans ce projet.

## 📊 Vue d'ensemble des services utilisés

Le projet utilise les services Azure suivants :

| Service | Type | Utilisation | Coût estimé/mois |
|---------|------|-------------|------------------|
| **AKS Control Plane** | PaaS | Orchestration Kubernetes | **GRATUIT** (Free tier) |
| **Virtual Machines** | IaaS | Nodes du cluster | 10-30€ selon config |
| **Load Balancer** | Réseau | Exposition publique | 1-2€ |
| **Managed Disks** | Stockage | Volumes persistants | 1-3€ |
| **Bande passante** | Réseau | Trafic sortant | 1-5€ selon usage |

**💡 Total estimé : 13-40€/mois** selon la configuration choisie.

## 🔍 Détail des coûts par service

### 1. Azure Kubernetes Service (AKS)

#### Control Plane
- **Prix** : **GRATUIT** avec le tier "Free"
- **Ce qui est inclus** :
  - API Server
  - etcd (base de données du cluster)
  - Scheduler
  - Controller Manager
- **Limitations** :
  - SLA de 99.5% (au lieu de 99.9% avec Uptime SLA payant)
  - Suffisant pour dev/test

#### Node Pool (Virtual Machines)

Le projet configure un node pool avec les options suivantes :

**Configuration par défaut (terraform/variables.tf)** :
```
node_count   = 1
node_vm_size = "Standard_B1s"
```

| VM Size | vCPU | RAM | Prix/mois* | Prix/jour* | Recommandé pour |
|---------|------|-----|------------|------------|-----------------|
| **Standard_B1s** | 1 | 1 GB | ~10€ | ~0.33€ | Tests légers, démo |
| **Standard_B2s** | 2 | 4 GB | ~30€ | ~1.00€ | Dev, tests complets |
| **Standard_B2ms** | 2 | 8 GB | ~60€ | ~2.00€ | Pré-prod |
| **Standard_D2s_v3** | 2 | 8 GB | ~75€ | ~2.50€ | Production |

*Tarifs région France Central, à jour en décembre 2025

**Optimisations configurées** :
- ✅ Kubenet (gratuit) au lieu d'Azure CNI (coût par IP)
- ✅ Pas de zones de disponibilité (évite le surcoût multi-zones)
- ✅ 1 seul node par défaut
- ✅ Disque OS de 64GB (minimum recommandé)

### 2. Load Balancer

#### Standard Load Balancer
- **Utilisation** : Exposition du frontend via `type: LoadBalancer`
- **Prix** : ~1-2€/mois
  - ~0.006€/heure (règle de load balancing)
  - ~0.006€/GB de données traitées
- **Note** : Créé automatiquement par Kubernetes pour les services LoadBalancer

**Alternative économique** :
- Utiliser Ingress Controller (1 seul LB pour tous les services)
- Voir [INGRESS.md](./INGRESS.md) pour la configuration

### 3. Managed Disks (Stockage persistant)

Le projet utilise des disques managés pour les données persistantes :

| Ressource | Type de disque | Taille | Prix/mois* |
|-----------|----------------|--------|------------|
| PostgreSQL | Standard SSD (E4) | 10 GB | ~0.60€ |
| Elasticsearch | Standard SSD (E4) | 10 GB | ~0.60€ |
| OS Disk (par node) | Standard SSD (E10) | 64 GB | ~3.80€ |

*Tarifs région France Central

**Configuration dans values-azure.yaml** :
```yaml
postgres:
  storage: "10Gi"
  storageClass: "managed-csi"

elasticsearch:
  storage: "10Gi"
  storageClass: "managed-csi"
```

**Total stockage** : ~5€/mois pour 1 node

### 4. Bande passante (Egress)

| Type de trafic | Prix |
|----------------|------|
| **Inbound** | GRATUIT |
| **Outbound < 100 GB/mois** | GRATUIT |
| **Outbound > 100 GB** | ~0.08€/GB |

**Estimation pour usage test/dev** : 1-2€/mois (rarement dépassé)

### 5. Public IP Address

- **Prix** : ~0.003€/heure (~2.20€/mois)
- **Utilisation** : IP publique du Load Balancer
- **Note** : Inclus dans le coût du Load Balancer ci-dessus

## 💸 Scénarios de coûts détaillés

### Scénario 1 : Configuration Minimale (Tests/Demo)
```hcl
node_count   = 1
node_vm_size = "Standard_B1s"
```

| Service | Coût/mois |
|---------|-----------|
| AKS Control Plane | **0€** |
| 1x Standard_B1s | 10€ |
| OS Disk (64GB) | 3.80€ |
| Load Balancer | 1.50€ |
| Managed Disks (PostgreSQL + ES) | 1.20€ |
| Bande passante | 1€ |
| **TOTAL** | **~17.50€/mois** |

**Avantages** :
- ✅ Coût très faible
- ✅ Suffisant pour tests et démos

**Limites** :
- ⚠️ Performances limitées
- ⚠️ Risque de `Insufficient CPU/Memory` avec tous les services actifs

### Scénario 2 : Configuration Recommandée (Dev)
```hcl
node_count   = 1
node_vm_size = "Standard_B2s"
```

| Service | Coût/mois |
|---------|-----------|
| AKS Control Plane | **0€** |
| 1x Standard_B2s | 30€ |
| OS Disk (64GB) | 3.80€ |
| Load Balancer | 1.50€ |
| Managed Disks | 1.20€ |
| Bande passante | 1€ |
| **TOTAL** | **~37.50€/mois** |

**Avantages** :
- ✅ Performances correctes
- ✅ Tous les services actifs sans problème
- ✅ Bon compromis coût/performance

### Scénario 3 : Configuration Production (Haute Disponibilité)
```hcl
node_count   = 3
node_vm_size = "Standard_D2s_v3"
```

| Service | Coût/mois |
|---------|-----------|
| AKS Control Plane + Uptime SLA | 60€ |
| 3x Standard_D2s_v3 | 225€ |
| OS Disks (3x 128GB) | 23€ |
| Load Balancer | 5€ |
| Managed Disks (avec réplication) | 10€ |
| Bande passante | 10€ |
| **TOTAL** | **~333€/mois** |

**Recommandé pour** :
- Production avec SLA requis
- Haute disponibilité (multi-zones)
- Trafic important

## 🎯 Recommandations pour optimiser les coûts

### 1. Arrêter le cluster quand non utilisé

```bash
# Arrêter (conserve la configuration)
az aks stop --resource-group rg-hello-world --name aks-hello-world

# Coût pendant l'arrêt : ~5€/mois (stockage uniquement)

# Redémarrer
az aks start --resource-group rg-hello-world --name aks-hello-world
```

**💡 Économie** : ~25€/mois si arrêté 80% du temps

### 2. Utiliser le mode Spot (VMs à prix réduit)

Non implémenté actuellement, mais possible avec :
```hcl
priority        = "Spot"
eviction_policy = "Delete"
spot_max_price  = -1  # Prix du marché
```

**💡 Économie** : jusqu'à 90% sur les VMs, mais peut être interrompu

### 3. Désactiver les services non essentiels

Dans `values-azure.yaml` :
```yaml
elasticsearch:
  enabled: false  # Économise ~1€/mois
logstash:
  enabled: false
kibana:
  enabled: false
```

**💡 Économie** : ~2€/mois

### 4. Utiliser des Reserved Instances (1-3 ans)

Pour usage long terme :
- Engagement 1 an : -40% de réduction
- Engagement 3 ans : -60% de réduction

**💡 Économie** : 12-18€/mois sur config Standard_B2s

### 5. Surveiller avec Azure Cost Management

```bash
# Activer les alertes de budget sur le portail Azure
# https://portal.azure.com/ → Cost Management + Billing → Budgets
```

**Configuration recommandée** :
- Budget mensuel : 50€
- Alerte à 80% (40€)
- Alerte à 100% (50€)

### 6. Nettoyer les ressources orphelines

```bash
# Lister les ressources
az resource list --resource-group rg-hello-world --output table

# Supprimer les disques non attachés
az disk list --query "[?diskState=='Unattached'].{Name:name, ResourceGroup:resourceGroup}" -o table
```

## 📈 Comparaison avec d'autres solutions

### vs Minikube/Docker (Local)

| Critère | Azure AKS | Local |
|---------|-----------|-------|
| **Coût** | 17-40€/mois | Gratuit |
| **Accessibilité** | Internet public | localhost uniquement |
| **Performances** | Cloud | Limitées par machine |
| **Haute dispo** | Oui (multi-nodes) | Non |
| **Recommandé pour** | Production, tests cloud | Développement |

### vs autres clouds

| Provider | Service | Coût/mois (équivalent) |
|----------|---------|------------------------|
| **Azure** | AKS (1x B2s) | ~37€ |
| **GCP** | GKE (1x e2-medium) | ~40€ |
| **AWS** | EKS (1x t3.medium) | ~75€* |

*EKS facture le control plane (~73€/mois)

**💡 Azure est compétitif** grâce au tier Free du control plane

## 🔄 Cycle de facturation et engagement

### Modèle Pay-As-You-Go

- ✅ Facturation à l'heure
- ✅ Pas d'engagement
- ✅ Arrêt = arrêt de facturation (sauf stockage)
- ⚠️ Prix standard

### Crédits gratuits Azure

**Compte gratuit Azure** :
- 200€ de crédit pendant 30 jours
- Suffisant pour 5-6 mois de tests (config minimale)

## 📊 Monitoring des coûts en temps réel

### Via Azure Portal

1. Accéder au portail : https://portal.azure.com/
2. Cost Management + Billing
3. Cost Analysis
4. Filtrer par Resource Group : `rg-hello-world`

### Via Azure CLI

```bash
# Coût du jour
az consumption usage list \
  --resource-group rg-hello-world \
  --start-date $(date -u -d '1 day ago' '+%Y-%m-%d') \
  --end-date $(date -u '+%Y-%m-%d') \
  --query "[].{Date:usageStart, Name:instanceName, Cost:pretaxCost}" \
  --output table

# Budget configuré
az consumption budget list \
  --resource-group rg-hello-world \
  --output table
```

### Via les tags Terraform

Le projet tag automatiquement toutes les ressources :
```hcl
tags = {
  Environment = "test"
  Project     = "hello-world"
  ManagedBy   = "terraform"
}
```

Ces tags permettent de filtrer les coûts dans Cost Management.

## 🚨 Alertes de coûts anormaux

### Signes d'une facturation anormale

- Bande passante > 10GB/jour (tests)
- Création de ressources non prévues
- Disques non supprimés après cleanup

### Actions préventives

1. **Configurer des alertes** (Azure Monitor)
2. **Réviser mensuellement** Cost Analysis
3. **Automatiser le cleanup** (script de nettoyage)
4. **Utiliser des limites** (Resource Quotas)

## 📝 Résumé et recommandations finales

### Pour des tests/démos (budget : 20€/mois)

```hcl
node_count   = 1
node_vm_size = "Standard_B1s"
```

- Arrêter le cluster quand non utilisé
- Désactiver Elasticsearch/Kibana
- Total : **~17€/mois** (ou 3€/mois si arrêté 80% du temps)

### Pour du développement actif (budget : 40€/mois)

```hcl
node_count   = 1
node_vm_size = "Standard_B2s"
```

- Tous les services actifs
- Performances correctes
- Total : **~37€/mois**

### Pour de la production (budget : 100€+/mois)

```hcl
node_count   = 2-3
node_vm_size = "Standard_D2s_v3"
```

- Haute disponibilité
- SLA 99.9%
- Auto-scaling configuré
- Total : **100-300€/mois** selon charge

## 🔗 Ressources utiles

- [Calculateur de prix Azure](https://azure.microsoft.com/fr-fr/pricing/calculator/)
- [Tarifs AKS](https://azure.microsoft.com/fr-fr/pricing/details/kubernetes-service/)
- [Tarifs VM](https://azure.microsoft.com/fr-fr/pricing/details/virtual-machines/linux/)
- [Tarifs Disques managés](https://azure.microsoft.com/fr-fr/pricing/details/managed-disks/)
- [Azure Cost Management](https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/overview)

---

**Dernière mise à jour** : Décembre 2025  
**Région de référence** : France Central  
**Devise** : EUR (€)

💡 **Astuce** : Utilisez le calculateur de prix Azure pour des estimations personnalisées selon votre région et votre usage.
