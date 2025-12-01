# Variables pour le déploiement AKS

variable "resource_group_name" {
  description = "Nom du resource group Azure"
  type        = string
  default     = "rg-hello-world"
}

variable "location" {
  description = "Région Azure"
  type        = string
  default     = "francecentral"
}

variable "cluster_name" {
  description = "Nom du cluster AKS"
  type        = string
  default     = "aks-hello-world"
}

variable "node_count" {
  description = "Nombre de nodes dans le cluster"
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "Taille des VMs pour les nodes (B2s_v2 = ~30€/mois, D2s_v3 = alternative)"
  type        = string
  default     = "Standard_B2s_v2"
}

variable "kubernetes_version" {
  description = "Version de Kubernetes"
  type        = string
  default     = "1.30"
}

variable "ghcr_username" {
  description = "Username GitHub pour accéder à GHCR"
  type        = string
  sensitive   = true
}

variable "ghcr_token" {
  description = "Token GitHub (PAT) pour accéder à GHCR"
  type        = string
  sensitive   = true
}
