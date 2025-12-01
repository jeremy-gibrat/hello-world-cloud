# Outputs pour faciliter l'utilisation du cluster

output "resource_group_name" {
  description = "Nom du resource group"
  value       = azurerm_resource_group.main.name
}

output "cluster_name" {
  description = "Nom du cluster AKS"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_id" {
  description = "ID du cluster AKS"
  value       = azurerm_kubernetes_cluster.main.id
}

output "kube_config" {
  description = "Configuration kubectl pour se connecter au cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "cluster_fqdn" {
  description = "FQDN du cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "get_credentials_command" {
  description = "Commande pour récupérer les credentials kubectl"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

output "estimated_monthly_cost" {
  description = "Estimation du coût mensuel (approximatif)"
  value       = "~10-30€ selon la VM size (B1s=10€, B2s=30€) + ~1-2€ de bande passante"
}
