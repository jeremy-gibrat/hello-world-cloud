#!/bin/bash

# Script pour nettoyer les ressources Azure

set -e

echo "🧹 Nettoyage des ressources Azure"
echo ""

# Vérifier les prérequis
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform n'est pas installé."
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "❌ Helm n'est pas installé."
    exit 1
fi

# Avertissement
echo "⚠️  ATTENTION: Cette action va supprimer:"
echo "   - Le release Helm 'hello-world'"
echo "   - Le cluster AKS"
echo "   - Le resource group et toutes les ressources Azure"
echo ""
read -p "Êtes-vous sûr de vouloir continuer ? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Nettoyage annulé"
    exit 0
fi

# Supprimer le release Helm
echo ""
echo "🗑️  Suppression du release Helm..."
if helm list | grep -q "hello-world"; then
    helm uninstall hello-world || true
    echo "✅ Release Helm supprimé"
else
    echo "ℹ️  Aucun release Helm trouvé"
fi

# Détruire l'infrastructure Terraform
echo ""
echo "🗑️  Destruction de l'infrastructure Azure..."
cd terraform

if [ ! -f terraform.tfstate ]; then
    echo "ℹ️  Aucun état Terraform trouvé. Infrastructure probablement déjà supprimée."
    cd ..
    exit 0
fi

terraform destroy -auto-approve

cd ..

echo ""
echo "✅ Nettoyage terminé!"
echo ""
echo "💡 N'oubliez pas de vérifier sur le portail Azure que toutes les ressources ont bien été supprimées."
echo "   https://portal.azure.com/"
