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
  }
}

provider "azurerm" {
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

  tags = {
    Environment = var.environment
    Project     = "BIDR"
  }
}

resource "azurerm_key_vault_secret" "django_secret_key" {
  name         = "django-secret-key"
  value        = random_password.django_secret_key.result
  key_vault_id = azurerm_key_vault.bidr.id

  tags = {
    Environment = var.environment
    Project     = "BIDR"
  }
}

resource "azurerm_key_vault_secret" "database_user" {
  name         = "database-user"
  value        = var.database_user
  key_vault_id = azurerm_key_vault.bidr.id

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
  kubernetes_version  = var.kubernetes_version

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
