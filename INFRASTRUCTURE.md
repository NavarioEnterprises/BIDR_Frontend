# BIDR Backend Infrastructure Deployment

This document provides comprehensive instructions for deploying the BIDR Backend microservices infrastructure on Azure using Terraform, Kubernetes, and automated CI/CD pipelines.

## 🏗️ Infrastructure Overview

The BIDR Backend infrastructure includes:

- **Azure Kubernetes Service (AKS)** - Container orchestration
- **Azure Container Registry (ACR)** - Docker image storage
- **Azure Key Vault** - Secrets management
- **PostgreSQL Flexible Server** - Primary database with service-specific databases
- **Redis Cache** - Caching and session storage
- **Azure Storage Account** - File storage
- **Application Insights** - Monitoring and telemetry
- **Log Analytics Workspace** - Centralized logging
- **Virtual Network with subnets** - Network isolation

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** - [Install here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Terraform** - [Install here](https://www.terraform.io/downloads.html)
3. **kubectl** - [Install here](https://kubernetes.io/docs/tasks/tools/)
4. **Docker** - [Install here](https://docs.docker.com/get-docker/)

### Deploy Infrastructure

1. **Login to Azure**:
   ```bash
   az login
   ```

2. **Deploy to Development Environment**:
   ```bash
   ./deploy-infrastructure.sh dev
   ```

3. **Deploy to UAT Environment**:
   ```bash
   ./deploy-infrastructure.sh uat
   ```

4. **Deploy to Production Environment**:
   ```bash
   ./deploy-infrastructure.sh prod
   ```

## 📋 Environment Configurations

### Development Environment
- **Resource Group**: `bidr-dev-k8s`
- **AKS Cluster**: `BIDR-dev-aks-cluster`
- **Container Registry**: `bidrnparusdevregistry2024`
- **Key Vault**: `bidr-nparus-dev-vault-2024`
- **Node Count**: 2 (Standard_D2s_v3)
- **Database**: Basic tier
- **Redis**: Basic tier

### UAT Environment
- **Resource Group**: `bidr-uat-k8s`
- **AKS Cluster**: `BIDR-uat-aks-cluster`
- **Container Registry**: `bidrnparusuatregistry2024`
- **Key Vault**: `bidr-nparus-uat-vault-2024`
- **Node Count**: 3 (Standard_D4s_v3)
- **Database**: General Purpose tier
- **Redis**: Standard tier

### Production Environment
- **Resource Group**: `bidr-k8s`
- **AKS Cluster**: `BIDR-aks-cluster`
- **Container Registry**: `bidrnparusregistry2024`
- **Key Vault**: `bidr-nparus-vault-2024`
- **Node Count**: 3+ (Standard_D4s_v3)
- **Database**: General Purpose tier
- **Redis**: Standard tier

## 🔐 Secrets Management

All credentials and sensitive configuration are stored in Azure Key Vault:

### Core Credentials
- `admin-password` - Global admin password
- `database-user` - Database username
- `database-password` - Database password
- `redis-password` - Redis authentication password
- `django-secret-key` - Django application secret

### Service-Specific Credentials
For each microservice (auth, chat, payment, resolution, product, notifications, transactions, reviews):
- `{service}-service-admin-password` - Service admin password
- `{service}-service-api-key` - Service-to-service API key
- `{service}-service-jwt-secret` - JWT signing secret
- `{service}-db-connection-string` - Database connection string

### Connection Strings
- `redis-connection-string` - Redis connection string
- `storage-connection-string` - Azure Storage connection string
- `app-insights-connection-string` - Application Insights connection string

## 📊 Retrieving Credentials

### View All Credentials
```bash
./get-admin-credentials.sh dev        # Development
./get-admin-credentials.sh uat        # UAT
./get-admin-credentials.sh prod       # Production
```

### Export to Environment File
```bash
./get-admin-credentials.sh dev export   # Creates .env.dev
./get-admin-credentials.sh uat export   # Creates .env.uat
./get-admin-credentials.sh prod export  # Creates .env.prod
```

## 🗄️ Database Architecture

### Service-Specific Databases
Each microservice has its own dedicated database:
- `auth_db` - Authentication service
- `chat_db` - Chat service
- `payment_db` - Payment service
- `resolution_db` - Resolution service
- `product_db` - Product management service
- `notifications_db` - Notifications service
- `transactions_db` - Transactions service
- `reviews_db` - Reviews and ratings service

### Database Connection
- **Server**: `{cluster-name}-psql-server.postgres.database.azure.com`
- **Port**: 5432
- **SSL Mode**: Required
- **Authentication**: Username/password from Key Vault

## 🔧 Service Configuration

Each Django microservice is configured with:

### Admin Interface Access
- URL: `http://<EXTERNAL_IP>/admin/{service}/`
- Username: `admin`
- Password: Retrieved from Key Vault

### Prometheus Metrics
- URL: `http://<SERVICE_IP>:8000/metrics`
- Integrated with `django-prometheus`
- Scraped by Prometheus for monitoring

### Service Communication
- API keys for secure service-to-service communication
- JWT tokens for user session management
- Redis for shared caching and session storage

## 🚢 CI/CD Deployment

### GitHub Actions Workflows

#### Development Pipeline (`.github/workflows/dev-deploy.yml`)
- **Trigger**: Push to `develop` branch
- **Environment**: Development
- **Features**:
  - Build and test all services
  - Code quality checks
  - Docker image builds
  - Deploy to AKS dev cluster
  - Basic smoke tests

#### UAT Pipeline (`.github/workflows/uat-deploy.yml`)
- **Trigger**: Push to `main` or `release/*` branches
- **Environment**: UAT
- **Features**:
  - Comprehensive testing
  - Security vulnerability scanning
  - Docker image security scans
  - Deploy to AKS UAT cluster
  - Performance testing
  - Comprehensive smoke tests

### Setup GitHub Secrets

Add the following secrets to your GitHub repository:

```yaml
AZURE_CREDENTIALS: |
  {
    "clientId": "<service-principal-client-id>",
    "clientSecret": "<service-principal-client-secret>",
    "subscriptionId": "<azure-subscription-id>",
    "tenantId": "<azure-tenant-id>"
  }
```

## 📈 Monitoring and Observability

### Grafana Dashboard
- URL: Access via kubectl port-forward or ingress
- Pre-configured dashboards for:
  - Service health and status
  - HTTP request metrics
  - Database connections
  - Redis performance
  - Infrastructure metrics

### Prometheus Metrics
- Service-specific metrics from each Django app
- Infrastructure metrics from AKS
- Custom business metrics

### Application Insights
- Distributed tracing
- Exception tracking
- Performance monitoring
- Custom telemetry

## 🛠️ Manual Deployment Steps

If you prefer manual deployment:

### 1. Initialize Terraform
```bash
cd terraform
terraform init
```

### 2. Plan Deployment
```bash
terraform plan -var-file="dev.tfvars" -out="dev.tfplan"
```

### 3. Apply Infrastructure
```bash
terraform apply "dev.tfplan"
```

### 4. Configure kubectl
```bash
az aks get-credentials --resource-group bidr-dev-k8s --name BIDR-dev-aks-cluster
```

### 5. Deploy Services to Kubernetes
```bash
kubectl apply -k k8s/overlays/development/
```

## 🔄 Scaling and Management

### Scale AKS Cluster
```bash
az aks scale --resource-group bidr-dev-k8s --name BIDR-dev-aks-cluster --node-count 5
```

### Update Kubernetes Version
```bash
az aks upgrade --resource-group bidr-dev-k8s --name BIDR-dev-aks-cluster --kubernetes-version 1.28.0
```

### Scale Individual Services
```bash
kubectl scale deployment bidr-auth-deployment --replicas=3 -n bidr-dev
```

## 🧹 Cleanup

### Destroy Infrastructure
```bash
cd terraform
terraform destroy -var-file="dev.tfvars"
```

### Delete Resource Group (Complete cleanup)
```bash
az group delete --name bidr-dev-k8s --yes --no-wait
```

## 🆘 Troubleshooting

### Common Issues

#### 1. Key Vault Access Denied
```bash
# Grant yourself Key Vault Administrator role
az role assignment create --assignee $(az account show --query user.name -o tsv) --role "Key Vault Administrator" --scope "/subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.KeyVault/vaults/<vault-name>"
```

#### 2. AKS Connection Issues
```bash
# Re-authenticate with AKS
az aks get-credentials --resource-group <rg-name> --name <cluster-name> --overwrite-existing
```

#### 3. Docker Registry Access
```bash
# Login to ACR
az acr login --name <registry-name>
```

#### 4. Service Health Check
```bash
# Check pod status
kubectl get pods --all-namespaces

# View logs
kubectl logs <pod-name> -n <namespace>

# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>
```

### Useful Commands

#### View Terraform State
```bash
cd terraform
terraform show
terraform output
```

#### Check Kubernetes Resources
```bash
kubectl get all --all-namespaces
kubectl get ingress --all-namespaces
kubectl get secrets --all-namespaces
```

#### Monitor Deployments
```bash
kubectl rollout status deployment/<deployment-name> -n <namespace>
kubectl rollout history deployment/<deployment-name> -n <namespace>
```

## 📞 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review Azure Activity Log in the portal
3. Examine Kubernetes events: `kubectl get events --all-namespaces`
4. Check Application Insights for application-level issues
5. Review Grafana dashboards for system metrics

## 📚 Additional Resources

- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Django Prometheus Integration](https://django-prometheus.readthedocs.io/)
- [Azure Key Vault Documentation](https://docs.microsoft.com/en-us/azure/key-vault/)

---

**Note**: Always ensure you're using the correct environment files and following security best practices. Never commit secrets to version control.
