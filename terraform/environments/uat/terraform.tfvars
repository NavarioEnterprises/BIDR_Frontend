# BIDR UAT Environment Configuration
# South Africa North deployment

# Basic Configuration
resource_group_name = "bidr-uat-k8s"
location           = "South Africa North"
environment        = "uat"

# Container Registry (must be globally unique)
acr_name = "bidrnparusuatregistry2024"
acr_sku  = "Basic"

# Key Vault (must be globally unique)
key_vault_name = "bidr-nparus-uat-vault-2024"

# AKS Cluster
aks_cluster_name   = "BIDR-uat-aks-cluster"
kubernetes_version = "1.28"

# Node Pool Configuration (medium for UAT)
node_count          = 2
node_vm_size        = "Standard_D2s_v3"
enable_auto_scaling = true
min_node_count      = 2
max_node_count      = 8

# Database Configuration
database_user = "bidruser"

# PostgreSQL Configuration (medium for UAT)
postgresql_version    = "15"
postgresql_sku       = "B_Standard_B2s"
postgresql_storage_mb = 65536

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

# Redis Configuration (medium for UAT)
redis_capacity = 1
redis_family   = "C"
redis_sku      = "Standard"

# Email Configuration (can be configured for UAT testing)
email_host_user     = ""
email_host_password = ""
