terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "test"
    Project     = "hello-world"
    ManagedBy   = "terraform"
  }
}

# AKS Cluster (Free Tier)
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  # Tier gratuit pour le control plane
  sku_tier = "Free"

  default_node_pool {
    name                        = "default"
    node_count                  = var.node_count
    vm_size                     = var.node_vm_size
    os_disk_size_gb             = 64
    type                        = "VirtualMachineScaleSets"
    enable_auto_scaling         = false
    temporary_name_for_rotation = "temp"

    # Optimisations pour réduire les coûts
    zones = null # Pas de zones de disponibilité (coût supplémentaire)
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "kubenet"  # Moins cher que Azure CNI
    load_balancer_sku = "standard"
    network_policy    = "calico"
  }

  # Désactiver les add-ons non essentiels pour économiser
  azure_policy_enabled = false
  
  tags = {
    Environment = "test"
    Project     = "hello-world"
    ManagedBy   = "terraform"
  }
}

# Configuration du provider Kubernetes pour utiliser le cluster AKS
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
}

# Utiliser null_resource pour créer le secret après que le cluster soit prêt
resource "null_resource" "create_ghcr_secret" {
  provisioner "local-exec" {
    command = <<-EOT
      az aks get-credentials --resource-group ${azurerm_kubernetes_cluster.main.resource_group_name} --name ${azurerm_kubernetes_cluster.main.name} --overwrite-existing
      kubectl create secret docker-registry ghcr-secret \
        --docker-server=ghcr.io \
        --docker-username=${var.ghcr_username} \
        --docker-password=${var.ghcr_token} \
        --namespace=default \
        --dry-run=client -o yaml | kubectl apply -f -
    EOT
  }

  depends_on = [azurerm_kubernetes_cluster.main]
  
  triggers = {
    cluster_id = azurerm_kubernetes_cluster.main.id
    username   = var.ghcr_username
    token      = md5(var.ghcr_token)
  }
}
