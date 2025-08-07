# BIDR Terraform Infrastructure

This directory contains Terraform configurations for deploying the BIDR application infrastructure on Azure.

## 🏗️ Infrastructure Components

The Terraform configuration creates the following Azure resources:

- **Resource Group**: Container for all BIDR resources
- **Azure Kubernetes Service (AKS)**: Managed Kubernetes cluster
- **Azure Container Registry (ACR)**: Private container registry for Docker images
- **Azure Key Vault**: Secure storage for secrets and passwords
- **Public IP**: Static IP address for the load balancer
- **Role Assignments**: Proper permissions for AKS to access ACR and Key Vault

## 📋 Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed and logged in
   ```bash
   az login
   ```

2. **Terraform** installed (version >= 1.0)
   ```bash
   terraform version
   ```

3. **Appropriate Azure permissions** to create:
   - Resource Groups
   - AKS clusters
   - Container Registries
   - Key Vaults
   - Role Assignments

## 🚀 Quick Deployment

### Option 1: Automated Deployment (Recommended)

Run the automated deployment script:

```bash
./deploy-terraform.sh
```

This script will:
- Check prerequisites
- Initialize Terraform
- Create and validate the execution plan
- Deploy the infrastructure
- Configure kubectl for the new cluster

### Option 2: Manual Deployment

1. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize Terraform**:
   ```bash
   cd terraform/
   terraform init
   ```

3. **Plan deployment**:
   ```bash
   terraform plan
   ```

4. **Apply configuration**:
   ```bash
   terraform apply
   ```

## ⚙️ Configuration

### Required Variables

Edit `terraform.tfvars` to customize your deployment:

```hcl
# Basic Configuration
resource_group_name = "bidr-k8s"
location           = "West US"
environment        = "prod"

# Container Registry (must be globally unique)
acr_name = "BIDRcontainerregistry"

# Key Vault (must be globally unique)
key_vault_name = "bidr-keyvault-12345"

# AKS Configuration
aks_cluster_name   = "BIDR-aks-cluster"
node_count         = 3
node_vm_size       = "Standard_D4s_v3"

# Database Configuration
database_user = "bidruser"
```

### Optional Variables

```hcl
# Email Configuration (for notifications)
email_host_user     = "your-email@example.com"
email_host_password = "your-app-password"

# Auto-scaling
enable_auto_scaling = true
min_node_count      = 2
max_node_count      = 10
```

## 🔐 Secrets Management

The Terraform configuration creates secure, randomly generated passwords for:

- Django Secret Key (50 characters)
- Database Password (32 characters)

These secrets are stored in Azure Key Vault and can be referenced by your Kubernetes deployments.

### Key Vault Integration

To use Key Vault secrets in your Kubernetes deployments:

1. **Deploy the CSI driver** (if not already installed):
   ```bash
   helm repo add csi-secrets-store-provider-azure https://azure.github.io/secrets-store-csi-driver-provider-azure/charts
   helm install csi-secrets-store-provider-azure/csi-secrets-store-provider-azure --generate-name
   ```

2. **Use the SecretProviderClass** in `../k8s/secret-keyvault.yaml`

3. **Mount secrets in your pods**:
   ```yaml
   spec:
     containers:
     - name: bidr-app
       volumeMounts:
       - name: secrets-store
         mountPath: "/mnt/secrets-store"
         readOnly: true
     volumes:
     - name: secrets-store
       csi:
         driver: secrets-store.csi.k8s.io
         readOnly: true
         volumeAttributes:
           secretProviderClass: "bidr-keyvault-secrets"
   ```

## 📊 Outputs

After deployment, Terraform provides these outputs:

```bash
# View all outputs
terraform output

# Specific outputs
terraform output acr_login_server
terraform output aks_cluster_name
terraform output key_vault_uri
```

### Key Outputs

- `acr_login_server`: URL for the container registry
- `aks_cluster_name`: Name of the Kubernetes cluster
- `key_vault_name`: Name of the Key Vault
- `public_ip_address`: External IP address
- `kubectl_config_command`: Command to configure kubectl

## 🔄 CI/CD Integration

Update your GitHub Actions workflow (`.github/workflows/deploy.yml`) with the Terraform outputs:

```yaml
env:
  RESOURCE_GROUP: # From terraform output resource_group_name
  AKS_CLUSTER: # From terraform output aks_cluster_name
  ACR_NAME: # From terraform output acr_name
```

## 🛠️ Management Commands

### Scale the cluster
```bash
# Scale nodes
az aks scale --resource-group bidr-k8s --name BIDR-aks-cluster --node-count 5
```

### Update cluster
```bash
# Get available versions
az aks get-upgrades --resource-group bidr-k8s --name BIDR-aks-cluster

# Upgrade cluster
az aks upgrade --resource-group bidr-k8s --name BIDR-aks-cluster --kubernetes-version 1.29
```

### Access Key Vault
```bash
# List secrets
az keyvault secret list --vault-name bidr-keyvault-12345

# Get secret value
az keyvault secret show --vault-name bidr-keyvault-12345 --name database-password
```

## 🗑️ Cleanup

To destroy all resources:

```bash
terraform destroy
```

**⚠️ Warning**: This will permanently delete all resources and data!

## 📁 File Structure

```
terraform/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output definitions
├── terraform.tfvars.example # Example configuration
├── terraform.tfvars        # Your configuration (create this)
└── README.md               # This documentation
```

## 🛡️ Security Best Practices

1. **Use Azure Key Vault** for all secrets in production
2. **Enable RBAC** on the AKS cluster (enabled by default)
3. **Use managed identities** instead of service principals
4. **Regularly update** Kubernetes and node images
5. **Implement network policies** for additional security
6. **Use private endpoints** for production deployments

## 💰 Cost Optimization

### Development Environment
- Use `Standard_B2s` for nodes
- Set `node_count = 1`
- Use `Basic` ACR SKU

### Production Environment
- Use `Standard_D4s_v3` for nodes (current default)
- Enable auto-scaling
- Consider spot instances for non-critical workloads

## 🆘 Troubleshooting

### Common Issues

1. **Key Vault name already exists**
   - Key Vault names must be globally unique
   - Update `key_vault_name` in terraform.tfvars

2. **Insufficient permissions**
   - Ensure your Azure account has Contributor role
   - Check Azure subscription limits

3. **Terraform state conflicts**
   ```bash
   terraform force-unlock <lock-id>
   ```

4. **AKS cluster not accessible**
   ```bash
   az aks get-credentials --resource-group bidr-k8s --name BIDR-aks-cluster --overwrite-existing
   ```

### Getting Help

- Check the Azure Activity Log for detailed error messages
- Use `terraform plan` to preview changes
- Review Azure documentation for specific resource requirements

## 📞 Support

For issues related to:
- **Terraform configuration**: Check this README and Terraform documentation
- **Azure resources**: Consult Azure documentation
- **BIDR application**: See the main project documentation
