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
  description = "Public IP address for the NGINX proxy"
  value       = azurerm_public_ip.nginx_proxy.ip_address
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

# PostgreSQL Outputs
output "postgresql_server_name" {
  description = "Name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.bidr.name
}

output "postgresql_fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.bidr.fqdn
}

output "postgresql_connection_string" {
  description = "Connection string template for PostgreSQL (password needs to be retrieved from Key Vault)"
  value       = "postgresql://${var.database_user}:@${azurerm_postgresql_flexible_server.bidr.fqdn}:5432/"
  sensitive   = true
}

# Redis Outputs
output "redis_hostname" {
  description = "Hostname of the Redis cache"
  value       = azurerm_redis_cache.bidr.hostname
}

output "redis_ssl_port" {
  description = "SSL port of the Redis cache"
  value       = azurerm_redis_cache.bidr.ssl_port
}

output "redis_primary_access_key" {
  description = "Primary access key for Redis cache"
  value       = azurerm_redis_cache.bidr.primary_access_key
  sensitive   = true
}

# Storage Account Outputs
output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.bidr.name
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = azurerm_storage_account.bidr.primary_blob_endpoint
}

# Application Insights
output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.bidr.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.bidr.connection_string
  sensitive   = true
}

# VNet and Subnet Outputs
output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.bidr.name
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

output "database_subnet_id" {
  description = "ID of the database subnet"
  value       = azurerm_subnet.database.id
}

# Load Balancer Outputs
output "load_balancer_public_ip" {
  description = "Public IP address of the load balancer - This is the main entry point for all services"
  value       = azurerm_public_ip.load_balancer.ip_address
}

output "load_balancer_fqdn" {
  description = "FQDN of the load balancer"
  value       = azurerm_public_ip.load_balancer.fqdn
}

output "load_balancer_name" {
  description = "Name of the Azure Load Balancer"
  value       = azurerm_lb.bidr.name
}

output "service_urls" {
  description = "Main service URLs accessible through the load balancer"
  value = {
    main_app         = "http://${azurerm_public_ip.load_balancer.ip_address}"
    auth_service     = "http://${azurerm_public_ip.load_balancer.ip_address}/auth"
    chat_service     = "http://${azurerm_public_ip.load_balancer.ip_address}/chat"
    payment_service  = "http://${azurerm_public_ip.load_balancer.ip_address}/payment"
    product_service  = "http://${azurerm_public_ip.load_balancer.ip_address}/product"
    notification_service = "http://${azurerm_public_ip.load_balancer.ip_address}/notifications"
    resolution_service = "http://${azurerm_public_ip.load_balancer.ip_address}/resolution"
    transaction_service = "http://${azurerm_public_ip.load_balancer.ip_address}/transactions"
    reviews_service = "http://${azurerm_public_ip.load_balancer.ip_address}/reviews"
  }
}
