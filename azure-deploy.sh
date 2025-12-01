#!/bin/bash

# Script pour déployer l'application sur Azure AKS avec Terraform et Helm

set -e

RELEASE_NAME="hello-world"

echo "🚀 Déploiement sur Azure AKS"
echo ""

# Option pour builder et pousser les images
read -p "Voulez-vous builder et pousser les images Docker avant le déploiement ? (yes/no): " build_images

if [ "$build_images" = "yes" ]; then
    echo ""
    ./build-and-push-azure.sh
    if [ $? -ne 0 ]; then
        echo "❌ Échec du build/push des images"
        exit 1
    fi
    echo ""
fi

# Vérifier les prérequis
echo "🔍 Vérification des prérequis..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform n'est pas installé. Installez-le: https://www.terraform.io/downloads"
    exit 1
fi

if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI n'est pas installé. Installez-le: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl n'est pas installé. Installez-le: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "❌ Helm n'est pas installé. Installez-le: https://helm.sh/docs/intro/install/"
    exit 1
fi

# Vérifier la connexion Azure
echo "🔐 Vérification de la connexion Azure..."
if ! az account show &> /dev/null; then
    echo "❌ Vous n'êtes pas connecté à Azure. Connectez-vous avec: az login"
    exit 1
fi

AZURE_SUBSCRIPTION=$(az account show --query name -o tsv)
echo "✅ Connecté à Azure (subscription: $AZURE_SUBSCRIPTION)"
echo ""

# Vérifier que terraform.tfvars existe
if [ ! -f terraform/terraform.tfvars ]; then
    echo "❌ Le fichier terraform/terraform.tfvars n'existe pas."
    echo "Copiez terraform/terraform.tfvars.example vers terraform/terraform.tfvars et configurez vos valeurs."
    exit 1
fi

# Terraform - Créer l'infrastructure
echo "📦 Initialisation de Terraform..."
cd terraform
terraform init

echo ""
echo "🏗️ Planification de l'infrastructure..."
terraform plan

echo ""
read -p "Voulez-vous appliquer ces changements ? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "❌ Déploiement annulé"
    exit 0
fi

echo ""
echo "🚀 Création de l'infrastructure Azure..."
terraform apply -auto-approve

# Récupérer les credentials du cluster AKS
echo ""
echo "🔑 Récupération des credentials kubectl..."
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
CLUSTER_NAME=$(terraform output -raw cluster_name)

az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing

echo ""
echo "✅ Configuration kubectl mise à jour"
cd ..

# Vérifier que le cluster est accessible
echo ""
echo "🔍 Vérification du cluster..."
kubectl cluster-info
kubectl get nodes

# Déployer avec Helm
echo ""
echo "📦 Déploiement de l'application avec Helm..."

# Vérifier que values-azure.yaml est configuré
if ! grep -q "your-github-username" helm/values-azure.yaml; then
    echo "⚠️  Attention: Assurez-vous d'avoir modifié les image repositories dans helm/values-azure.yaml"
    read -p "Voulez-vous continuer ? (yes/no): " confirm_helm
    if [ "$confirm_helm" != "yes" ]; then
        echo "❌ Déploiement annulé. Modifiez helm/values-azure.yaml avant de continuer."
        exit 0
    fi
fi

if helm list | grep -q "$RELEASE_NAME"; then
    echo "📦 Mise à jour du release existant..."
    helm upgrade $RELEASE_NAME ./helm -f ./helm/values-azure.yaml
else
    echo "📦 Installation du nouveau release..."
    helm install $RELEASE_NAME ./helm -f ./helm/values-azure.yaml
fi

echo ""
echo "⏳ Attente du démarrage des pods..."
kubectl wait --for=condition=ready pod -l app=hello-world-backend --timeout=300s
kubectl wait --for=condition=ready pod -l app=hello-world-frontend --timeout=300s

echo ""
echo "✅ Application déployée avec succès sur Azure AKS!"
echo ""
echo "📊 État des pods:"
kubectl get pods

echo ""
echo "🌐 Services:"
kubectl get services

echo ""
echo "🌍 Pour accéder au frontend, récupérez l'IP externe du LoadBalancer:"
echo "   kubectl get service hello-world-frontend-service"
echo ""
echo "⏳ Le LoadBalancer peut prendre 2-3 minutes pour obtenir une IP publique."
echo "   Surveillez avec: kubectl get service hello-world-frontend-service --watch"
echo ""
echo "💰 Estimation du coût mensuel: ~10-30€ selon votre configuration"
