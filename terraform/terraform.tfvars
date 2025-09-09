# BIDR Terraform Configuration
# Configuration for nparus@gmail.com Azure deployment

# Basic Configuration
resource_group_name = "bidr-k8s"
location           = "South Africa North"
environment        = "prod"

# Container Registry (must be globally unique)
acr_name = "bidrnparusregistry2024"
acr_sku  = "Basic"

# Key Vault (must be globally unique)
key_vault_name = "bidr-nparus-vault-2024"

# AKS Cluster
aks_cluster_name   = "BIDR-aks-cluster"
kubernetes_version = "1.28"

# Node Pool Configuration
node_count          = 3
node_vm_size        = "Standard_D4s_v3"
enable_auto_scaling = true
min_node_count      = 2
max_node_count      = 10

# Database Configuration
database_user = "bidruser"

# PostgreSQL Configuration
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

# Redis Configuration  
redis_capacity = 2
redis_family   = "C"
redis_sku      = "Standard"

# Email Configuration (leave empty for now, can be configured later)
email_host_user     = ""
email_host_password = ""
