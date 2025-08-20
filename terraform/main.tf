terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "bidr" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "BIDR"
    ManagedBy   = "Terraform"
  }
}

# Azure Container Registry
resource "azurerm_container_registry" "bidr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.bidr.name
  location            = azurerm_resource_group.bidr.location
  sku                 = var.acr_sku
  admin_enabled       = true

  tags = {
    Environment = var.environment
    Project     = "BIDR"
    ManagedBy   = "Terraform"
  }
}

# Key Vault for secrets management
resource "azurerm_key_vault" "bidr" {
  name                = var.key_vault_name
  location            = azurerm_resource_group.bidr.location
  resource_group_name = azurerm_resource_group.bidr.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enable_rbac_authorization = true

  tags = {
    Environment = var.environment
    Project     = "BIDR"
    ManagedBy   = "Terraform"
  }
}

# Key Vault access policy for current user (deployer)
resource "azurerm_role_assignment" "current_user_keyvault_admin" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.bidr.id
}

# Wait for role assignment before creating secrets
resource "time_sleep" "wait_for_keyvault_rbac" {
  depends_on      = [azurerm_role_assignment.current_user_keyvault_admin]
  create_duration = "60s"
}

# Generate random passwords for database and Django
resource "random_password" "database_password" {
  length  = 32
  special = true
}

resource "random_password" "django_secret_key" {
  length  = 50
  special = true
}

# Key Vault Secrets
resource "azurerm_key_vault_secret" "database_password" {
  name         = "database-password"
  value        = random_password.database_password.result
  key_vault_id = azurerm_key_vault.bidr.id

  depends_on = [time_sleep.wait_for_keyvault_rbac]

  tags = {
    Environment = var.environment
    Project     = "BIDR"
  }
}

resource "azurerm_key_vault_secret" "django_secret_key" {
  name         = "django-secret-key"
  value        = random_password.django_secret_key.result
  key_vault_id = azurerm_key_vault.bidr.id

  depends_on = [time_sleep.wait_for_keyvault_rbac]

  tags = {
    Environment = var.environment
    Project     = "BIDR"
  }
}

resource "azurerm_key_vault_secret" "database_user" {
  name         = "database-user"
  value        = var.database_user
  key_vault_id = azurerm_key_vault.bidr.id

  depends_on = [time_sleep.wait_for_keyvault_rbac]

  tags = {
    Environment = var.environment
    Project     = "BIDR"
  }
}

# Azure Kubernetes Service
resource "azurerm_kubernetes_cluster" "bidr" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.bidr.location
  resource_group_name = azurerm_resource_group.bidr.name
  dns_prefix          = "${var.aks_cluster_name}-dns"
  kubernetes_version  = "1.30.14"

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = var.node_vm_size
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = var.enable_auto_scaling
    min_count           = var.enable_auto_scaling ? var.min_node_count : null
    max_count           = var.enable_auto_scaling ? var.max_node_count : null

    tags = {
      Environment = var.environment
      Project     = "BIDR"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "kubenet"
    network_policy = "calico"
  }

  tags = {
    Environment = var.environment
    Project     = "BIDR"
    ManagedBy   = "Terraform"
  }
}

# Role assignment for AKS to pull images from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.bidr.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.bidr.id
  skip_service_principal_aad_check = true
}

# Role assignment for Key Vault access
resource "azurerm_role_assignment" "aks_keyvault_secrets_user" {
  principal_id         = azurerm_kubernetes_cluster.bidr.identity[0].principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.bidr.id
}

# Create Virtual Network
resource "azurerm_virtual_network" "bidr" {
  name                = "${var.aks_cluster_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.bidr.location
  resource_group_name = azurerm_resource_group.bidr.name

  tags = {
    Environment = var.environment
    Project     = "BIDR"
    ManagedBy   = "Terraform"
  }
}

# Create Subnet for AKS
resource "azurerm_subnet" "aks" {
  name                 = "${var.aks_cluster_name}-aks-subnet"
  resource_group_name  = azurerm_resource_group.bidr.name
  virtual_network_name = azurerm_virtual_network.bidr.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create Subnet for Database
resource "azurerm_subnet" "database" {
  name                 = "${var.aks_cluster_name}-db-subnet"
  resource_group_name  = azurerm_resource_group.bidr.name
  virtual_network_name = azurerm_virtual_network.bidr.name
  address_prefixes     = ["10.0.2.0/24"]
  
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Create Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgresql" {
  name                = "${var.aks_cluster_name}-pdz.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.bidr.name

  tags = {
    Environment = var.environment
    Project     = "BIDR"
    ManagedBy   = "Terraform"
  }
}

# Create Virtual Network Link
resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "${var.aks_cluster_name}-pdzvnetlink"
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = azurerm_virtual_network.bidr.id
  resource_group_name   = azurerm_resource_group.bidr.name

  tags = {
    Environment = var.environment
    Project     = "BIDR"
    ManagedBy   = "Terraform"
  }
}

# Generate service-specific and admin passwords
resource "random_password" "redis_password" {
  length  = 32
  special = false
}

resource "random_password" "admin_password" {
  length  = 16
  special = true
}

# Generate service-specific admin passwords for each service
resource "random_password" "service_admin_passwords" {
  for_each = toset([
    "auth",
    "chat", 
    "payment",
    "resolution",
    "product",
    "notifications",
    "transactions",
    "reviews"
  ])
  length  = 16
  special = true
}

# Generate API keys for service-to-service communication
resource "random_password" "service_api_keys" {
  for_each = toset([
    "auth",
    "chat", 
    "payment",
    "resolution",
    "product",
    "notifications",
    "transactions",
    "reviews"
  ])
  length  = 64
  special = false
}

# Generate JWT secrets for each service
resource "random_password" "service_jwt_secrets" {
  for_each = toset([
    "auth",
    "chat", 
    "payment",
    "resolution",
    "product",
    "notifications",
    "transactions",
    "reviews"
  ])
  length  = 64
  special = true
}

# Core secrets
resource "azurerm_key_vault_secret" "redis_password" {
  name         = "redis-password"
  value        = random_password.redis_password.result
  key_vault_id = azurerm_key_vault.bidr.id

  depends_on = [time_sleep.wait_for_keyvault_rbac]

  tags = {
    Environment = var.environment
    Project     = "BIDR"
  }
}

resource "azurerm_key_vault_secret" "admin_password" {
  name         = "admin-password"
  value        = random_password.admin_password.result
  key_vault_id = azurerm_key_vault.bidr.id

  depends_on = [time_sleep.wait_for_keyvault_rbac]

  tags = {
    Environment = var.environment
    Project     = "BIDR"
  }
}

resource "azurerm_key_vault_secret" "email_host_user" {
  name         = "email-host-user"
  value        = var.email_host_user
  key_vault_id = azurerm_key_vault.bidr.id

  depends_on = [time_sleep.wait_for_keyvault_rbac]

  tags = {
    Environment = var.environment
    Project     = "BIDR"
  }
}

resource "azurerm_key_vault_secret" "email_host_password" {
  name         = "email-host-password"
  value        = var.email_host_password
  key_vault_id = azurerm_key_vault.bidr.id

  depends_on = [time_sleep.wait_for_keyvault_rbac]

  tags = {
    Environment = var.environment
    Project     = "BIDR"
  }
}

# Service-specific admin passwords
resource "azurerm_key_vault_secret" "service_admin_passwords" {
  for_each     = random_password.service_admin_passwords
  name         = "${each.key}-service-admin-password"
  value        = each.value.result
  key_vault_id = azurerm_key_vault.bidr.id

  depends_on = [time_sleep.wait_for_keyvault_rbac]

  tags = {
    Environment = var.environment
    Project     = "BIDR"
    Service     = each.key
  }
}

# Service-to-service API keys
resource "azurerm_key_vault_secret" "service_api_keys" {
  for_each     = random_password.service_api_keys
  name         = "${each.key}-service-api-key"
  value        = each.value.result
  key_vault_id = azurerm_key_vault.bidr.id

  depends_on = [time_sleep.wait_for_keyvault_rbac]

  tags = {
    Environment = var.environment
    Project     = "BIDR"
    Service     = each.key
  }
}

# Service-specific JWT secrets
resource "azurerm_key_vault_secret" "service_jwt_secrets" {
  for_each     = random_password.service_jwt_secrets
  name         = "${each.key}-service-jwt-secret"
  value        = each.value.result
  key_vault_id = azurerm_key_vault.bidr.id

  depends_on = [time_sleep.wait_for_keyvault_rbac]

  tags = {
    Environment = var.environment
    Project     = "BIDR"
    Service     = each.key
  }
}

# Database connection strings for each service
resource "azurerm_key_vault_secret" "service_db_connection_strings" {
  for_each     = toset(var.database_names)
  name         = "${replace(each.key, "_db", "")}-db-connection-string"
  value        = "postgresql://${var.database_user}:${random_password.database_password.result}@${azurerm_postgresql_flexible_server.bidr.fqdn}:5432/${each.key}?sslmode=require"
  key_vault_id = azurerm_key_vault.bidr.id

  depends_on = [azurerm_postgresql_flexible_server_database.databases, time_sleep.wait_for_keyvault_rbac]

  tags = {
    Environment = var.environment
    Project     = "BIDR"
    Service     = replace(each.key, "_db", "")
  }
}

# Redis connection string
resource "azurerm_key_vault_secret" "redis_connection_string" {
  name         = "redis-connection-string"
  value        = "rediss://:${random_password.redis_password.result}@${azurerm_redis_cache.bidr.hostname}:${azurerm_redis_cache.bidr.ssl_port}"
  key_vault_id = azurerm_key_vault.bidr.id

  depends_on = [time_sleep.wait_for_keyvault_rbac]

  tags = {
    Environment = var.environment
    Project     = "BIDR"
  }
}

# Storage account connection string
resource "azurerm_key_vault_secret" "storage_connection_string" {
  name         = "storage-connection-string"
  value        = azurerm_storage_account.bidr.primary_connection_string
  key_vault_id = azurerm_key_vault.bidr.id

  depends_on = [time_sleep.wait_for_keyvault_rbac]

  tags = {
    Environment = var.environment
    Project     = "BIDR"
  }
}

# Application Insights connection string
resource "azurerm_key_vault_secret" "app_insights_connection_string" {
  name         = "app-insights-connection-string"
  value        = azurerm_application_insights.bidr.connection_string
  key_vault_id = azurerm_key_vault.bidr.id

  depends_on = [time_sleep.wait_for_keyvault_rbac]

  tags = {
    Environment = var.environment
    Project     = "BIDR"
  }
}

# Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "bidr" {
  name                = "${var.aks_cluster_name}-logs"
  location            = azurerm_resource_group.bidr.location
  resource_group_name = azurerm_resource_group.bidr.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
    Project     = "BIDR"
    ManagedBy   = "Terraform"
  }
}

# Create Application Insights
resource "azurerm_application_insights" "bidr" {
  name                = "${var.aks_cluster_name}-appinsights"
  location            = azurerm_resource_group.bidr.location
  resource_group_name = azurerm_resource_group.bidr.name
  workspace_id        = azurerm_log_analytics_workspace.bidr.id
  application_type    = "web"

  tags = {
    Environment = var.environment
    Project     = "BIDR"
    ManagedBy   = "Terraform"
  }
}

# Create Storage Account
resource "azurerm_storage_account" "bidr" {
  name                     = lower(replace("${var.aks_cluster_name}storage", "-", ""))
  resource_group_name      = azurerm_resource_group.bidr.name
  location                 = azurerm_resource_group.bidr.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD", "POST", "PUT"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 300
    }
  }

  tags = {
    Environment = var.environment
    Project     = "BIDR"
    ManagedBy   = "Terraform"
  }
}

# Create PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "bidr" {
  name                          = lower("${replace(var.aks_cluster_name, "_", "-")}-psql-server")
  resource_group_name           = azurerm_resource_group.bidr.name
  location                      = azurerm_resource_group.bidr.location
  version                       = var.postgresql_version
  delegated_subnet_id           = azurerm_subnet.database.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgresql.id
  administrator_login           = var.database_user
  administrator_password        = random_password.database_password.result
  zone                          = "1"
  storage_mb                    = var.postgresql_storage_mb
  sku_name                     = var.postgresql_sku
  public_network_access_enabled = false

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql]

  tags = {
    Environment = var.environment
    Project     = "BIDR"
    ManagedBy   = "Terraform"
  }
}

# Create databases for each service
resource "azurerm_postgresql_flexible_server_database" "databases" {
  for_each  = toset(var.database_names)
  name      = each.value
  server_id = azurerm_postgresql_flexible_server.bidr.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Create Redis Cache
resource "azurerm_redis_cache" "bidr" {
  name                = "${var.aks_cluster_name}-redis"
  location            = azurerm_resource_group.bidr.location
  resource_group_name = azurerm_resource_group.bidr.name
  capacity            = var.redis_capacity
  family              = var.redis_family
  sku_name            = var.redis_sku
  non_ssl_port_enabled = false
  minimum_tls_version = "1.2"

  redis_configuration {
    authentication_enabled = true
  }

  tags = {
    Environment = var.environment
    Project     = "BIDR"
    ManagedBy   = "Terraform"
  }
}

# Public IP for Load Balancer (optional - AKS creates this automatically)
resource "azurerm_public_ip" "bidr_lb" {
  name                = "${var.aks_cluster_name}-lb-ip"
  resource_group_name = azurerm_kubernetes_cluster.bidr.node_resource_group
  location            = azurerm_resource_group.bidr.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    Project     = "BIDR"
    ManagedBy   = "Terraform"
  }
}
