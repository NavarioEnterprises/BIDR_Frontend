# BIDR UAT Environment Configuration

# Basic Configuration
resource_group_name = "bidr-uat-k8s"
location           = "East US"
environment        = "uat"

# Container Registry (must be globally unique)
acr_name = "bidrnparusuatregistry2024"
acr_sku  = "Standard"

# Key Vault (must be globally unique)
key_vault_name = "bidr-uat-vault-2024"

# AKS Cluster
aks_cluster_name   = "BIDR-uat-aks-cluster"
kubernetes_version = "1.28"

# Node Pool Configuration (small for UAT - reduced resource usage)
node_count          = 2
node_vm_size        = "Standard_B2s"
enable_auto_scaling = true
min_node_count      = 1
max_node_count      = 3

# Database Configuration
database_user = "bidruser"

# PostgreSQL Configuration (small for UAT)
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

# Redis Configuration (small for UAT)
redis_capacity = 0
redis_family   = "C"
redis_sku      = "Basic"

# Email Configuration (UAT settings)
email_host_user     = "nparus@gmail.com"
email_host_password = ""

# SSH public key for VM access
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDqUNawrVlOjuxJoZNPGZvRbQ8d/VGu8KyAodaW7ZZEJBE6rt43Yxr3ocG2XFo2FnGLtxQszv7l9F4iNyoy2AeCaaCbViDTd3DGsOInMy9KwXrqmwTjp26TrhFUQCdf/hJyvtBxGG3LBdRbGGJM17a41c0K69JwIRYBOWnBLcncSpoW556aVLGrF/B7E28pFDVpECQEHqzPMMtUXjCW+a6geXbclyC4nQpRSSocJ9KVbos5GYvRR0ZEYqv0sgoYPxJygWu0MF706sR16gpmpAIh9EZSWbK5NR9IFMW4We96NV9/r2I9+MF54QeJ+TStB14V6yUlMH699YleZ4s32bF9 bidr-deployment"
