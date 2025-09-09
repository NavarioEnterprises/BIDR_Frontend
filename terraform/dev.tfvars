# BIDR Development Environment Configuration

# Basic Configuration
resource_group_name = "bidr-dev-k8s"
location           = "South Africa North"
environment        = "dev"

# Container Registry (must be globally unique)
acr_name = "bidrnparusdevregistry2024"
acr_sku  = "Basic"

# Key Vault (must be globally unique - alphanumeric and dashes only, 3-24 chars)
key_vault_name = "bidr-nparus-dev-vault"

# AKS Cluster
aks_cluster_name   = "BIDR-dev-aks-cluster"
kubernetes_version = "1.28"

# Node Pool Configuration (smaller for dev)
node_count          = 2
node_vm_size        = "Standard_D2s_v3"
enable_auto_scaling = true
min_node_count      = 1
max_node_count      = 5

# Database Configuration
database_user = "bidruser"

# PostgreSQL Configuration (smaller for dev)
postgresql_version    = "15"
postgresql_sku       = "B_Standard_B1ms"
postgresql_storage_mb = 32768

# Database Names for all services
database_names = [
  "auth_db",
  "chat_db", 
  "payment_db",
  "resolution_db",
  "product_db",
  "notifications_db",
  "transactions_db",
  "reviews_db"
]

# Redis Configuration (smaller for dev)
redis_capacity = 1
redis_family   = "C"
redis_sku      = "Basic"

# Email Configuration (dev settings)
email_host_user     = "dev@bidr.local"
email_host_password = ""
