variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "bidr-k8s"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West US"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "BIDRcontainerregistry"
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

variable "key_vault_name" {
  description = "Name of the Azure Key Vault"
  type        = string
  default     = "bidr-keyvault"
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "BIDR-aks-cluster"
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to use"
  type        = string
  default     = "1.28"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 3
}

variable "node_vm_size" {
  description = "Size of the VM for nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "enable_auto_scaling" {
  description = "Enable auto scaling for the node pool"
  type        = bool
  default     = true
}

variable "min_node_count" {
  description = "Minimum number of nodes when auto scaling is enabled"
  type        = number
  default     = 2
}

variable "max_node_count" {
  description = "Maximum number of nodes when auto scaling is enabled"
  type        = number
  default     = 10
}

variable "database_user" {
  description = "Database username for BIDR application"
  type        = string
  default     = "bidruser"
  sensitive   = true
}

variable "email_host_user" {
  description = "Email host user for SMTP configuration"
  type        = string
  default     = ""
  sensitive   = true
}

variable "email_host_password" {
  description = "Email host password for SMTP configuration"
  type        = string
  default     = ""
  sensitive   = true
}
