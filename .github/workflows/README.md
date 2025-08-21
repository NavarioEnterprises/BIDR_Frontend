# BIDR CI/CD with GitHub Actions

This repository includes automated CI/CD workflows that deploy your BIDR application to Azure Kubernetes Service (AKS) when code is pushed to the `main` branch.

## 🚀 Workflows

### 1. Application Deployment (`deploy.yml`)
- **Triggers**: Push to `main` branch (for any service code changes)
- **Features**:
  - Detects changes in specific service folders
  - Builds and pushes Docker images to Azure Container Registry (ACR)
  - Deploys only changed services to AKS
  - Runs health checks after deployment
  - Smart caching for faster builds

### 2. Infrastructure Deployment (`infrastructure.yml`)
- **Triggers**: Push to `main` branch (for `terraform/` or `k8s/` changes)
- **Features**:
  - Terraform plan and apply for infrastructure changes
  - Kubernetes manifest validation and deployment
  - Infrastructure health checks

## 🔧 Required GitHub Secrets

Before the workflows can run, you need to add these secrets to your GitHub repository:

### Go to: Settings → Secrets and Variables → Actions → Repository secrets

1. **`AZURE_CREDENTIALS`** - Service Principal credentials for Azure access
   ```json
   {
     "clientId": "your-client-id",
     "clientSecret": "your-client-secret", 
     "subscriptionId": "your-subscription-id",
     "tenantId": "your-tenant-id"
   }
   ```

2. **`ACR_USERNAME`** - Azure Container Registry username
   ```
   bidrnparusdevregistry2024
   ```

3. **`ACR_PASSWORD`** - Azure Container Registry password
   ```
   your-acr-password
   ```

## 📋 Setting Up Azure Service Principal

Run these commands to create the service principal:

```bash
# Create service principal
az ad sp create-for-rbac --name "BIDR-GitHub-Actions" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/bidr-dev-k8s \
  --sdk-auth

# Grant AKS permissions
az role assignment create \
  --assignee {client-id} \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope /subscriptions/{subscription-id}/resourceGroups/bidr-dev-k8s/providers/Microsoft.ContainerService/managedClusters/BIDR-dev-aks-cluster

# Grant ACR permissions  
az role assignment create \
  --assignee {client-id} \
  --role "AcrPush" \
  --scope /subscriptions/{subscription-id}/resourceGroups/bidr-dev-k8s/providers/Microsoft.ContainerRegistry/registries/bidrnparusdevregistry2024
```

## 🏗️ Service Folder Structure

The workflow expects this folder structure:

```
BIDR_Backend/
├── authentication_service/    # Auth service code + Dockerfile
├── chat_service/             # Chat service code + Dockerfile  
├── payment_service/          # Payment service code + Dockerfile
├── inventory_service/        # Product service code + Dockerfile
├── notifications_service/    # Notifications service code + Dockerfile
├── transactions_service/     # Transactions service code + Dockerfile
├── reviews_service/          # Reviews service code + Dockerfile
├── resolution_service/       # Resolution service code + Dockerfile
├── terraform/                # Infrastructure as Code
├── k8s/                      # Kubernetes manifests
└── .github/workflows/        # CI/CD workflows
```

## 🔄 How It Works

### On Push to Main Branch:

1. **Change Detection**: Workflows detect which services/infrastructure changed
2. **Build Phase**: Changed services get new Docker images built and pushed to ACR
3. **Deploy Phase**: AKS deployments are updated with new image tags
4. **Health Check**: Services are tested through the load balancer
5. **Notification**: Success/failure status is reported

### Service Mapping:
- `authentication_service/` → `auth-service` image → `auth-service` deployment
- `chat_service/` → `chat-service` image → `chat-service` deployment  
- `inventory_service/` → `product-service` image → `product-management-service` deployment
- And so on...

## 🌐 Access Points After Deployment

Your application will be available at: **http://4.221.172.198/**

Service endpoints:
- **Auth**: http://4.221.172.198/admin/
- **Chat**: http://4.221.172.198/chat/
- **Products**: http://4.221.172.198/products/
- **Payments**: http://4.221.172.198/payments/
- **Notifications**: http://4.221.172.198/notifications/
- **Transactions**: http://4.221.172.198/transactions/
- **Reviews**: http://4.221.172.198/reviews/
- **Resolution**: http://4.221.172.198/resolution/

## 🛠️ Local Testing

To test the workflows locally before pushing:

```bash
# Validate Kubernetes manifests
kubectl apply --validate=true --dry-run=client -k k8s/

# Test Terraform plan
cd terraform && terraform plan

# Build a service locally
docker build -t test-service ./authentication_service/
```

## 🔍 Troubleshooting

### Common Issues:

1. **"Failed to get credentials"** - Check `AZURE_CREDENTIALS` secret format
2. **"Authentication failed"** - Verify service principal has correct permissions
3. **"Image pull failed"** - Check ACR credentials and image names
4. **"Deployment timeout"** - Check pod resource requests vs. cluster capacity

### Viewing Logs:
- **GitHub Actions**: Go to Actions tab in your repo
- **AKS Pods**: `kubectl logs -n bidr deployment/service-name`
- **Service Health**: Test endpoints at http://4.221.172.198/

## 📊 Monitoring

After deployment, monitor your services:

```bash
# Check all pods
kubectl get pods -n bidr

# Check service endpoints  
kubectl get svc -n bidr

# View recent deployments
kubectl get deployments -n bidr

# Check logs for a specific service
kubectl logs -n bidr deployment/auth-service --tail=50
```

## 🎯 Next Steps

1. Add the required secrets to your GitHub repository
2. Push changes to the `main` branch
3. Monitor the Actions tab for deployment progress
4. Access your application at http://4.221.172.198/

Your BIDR application now has fully automated CI/CD! 🚀
