output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.bidr.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.bidr.name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.bidr.id
}

output "aks_node_resource_group" {
  description = "Resource group containing the AKS nodes"
  value       = azurerm_kubernetes_cluster.bidr.node_resource_group
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.bidr.name
}

output "acr_login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.bidr.login_server
}

output "acr_admin_username" {
  description = "Admin username for Azure Container Registry"
  value       = azurerm_container_registry.bidr.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "Admin password for Azure Container Registry"
  value       = azurerm_container_registry.bidr.admin_password
  sensitive   = true
}

output "key_vault_name" {
  description = "Name of the Azure Key Vault"
  value       = azurerm_key_vault.bidr.name
}

output "key_vault_uri" {
  description = "URI of the Azure Key Vault"
  value       = azurerm_key_vault.bidr.vault_uri
}

output "public_ip_address" {
  description = "Public IP address for the load balancer"
  value       = azurerm_public_ip.bidr_lb.ip_address
}

output "kube_config" {
  description = "Raw kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.bidr.kube_config_raw
  sensitive   = true
}

# Generated passwords (for reference, not for direct use)
output "database_password_key_vault_reference" {
  description = "Key Vault reference for the database password"
  value       = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.bidr.name};SecretName=${azurerm_key_vault_secret.database_password.name})"
}

output "django_secret_key_vault_reference" {
  description = "Key Vault reference for the Django secret key"
  value       = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.bidr.name};SecretName=${azurerm_key_vault_secret.django_secret_key.name})"
}

# Connection strings and commands
output "kubectl_config_command" {
  description = "Command to configure kubectl for this cluster"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.bidr.name} --name ${azurerm_kubernetes_cluster.bidr.name}"
}

output "acr_login_command" {
  description = "Command to login to Azure Container Registry"
  value       = "az acr login --name ${azurerm_container_registry.bidr.name}"
}
