#!/bin/bash

# Script pour générer terraform.tfvars depuis le fichier .env

set -e

if [ ! -f ../.env ]; then
    echo "❌ Fichier .env non trouvé dans le répertoire parent"
    echo "Copiez .env.example vers .env et configurez-le."
    exit 1
fi

echo "📝 Génération de terraform.tfvars depuis .env..."

# Charger les variables depuis .env
export $(cat ../.env | grep -v '^#' | xargs)

# Générer terraform.tfvars
cat > terraform.tfvars << EOF
# Configuration de base
resource_group_name = "${RESOURCE_GROUP_NAME}"
location            = "${LOCATION}"
cluster_name        = "${CLUSTER_NAME}"

# Configuration des nodes
node_count   = ${NODE_COUNT}
node_vm_size = "${NODE_VM_SIZE}"

# Version Kubernetes
kubernetes_version = "${KUBERNETES_VERSION}"

# GitHub Container Registry credentials
ghcr_username = "${GHCR_USERNAME}"
ghcr_token    = "${GHCR_TOKEN}"
EOF

echo "✅ terraform.tfvars généré avec succès"
echo ""
echo "⚠️  IMPORTANT: Ne committez jamais terraform.tfvars (contient des secrets)"
