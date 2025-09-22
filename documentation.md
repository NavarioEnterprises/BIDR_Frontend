# BIDR Backend - Azure Kubernetes Service Deployment Guide

This guide documents the deployment of the BIDR backend API server to Azure Kubernetes Service (AKS).

## Prerequisites

Before you begin, ensure you have:

1. **Azure CLI** installed and logged in
2. **Docker** installed and running
3. **kubectl** installed
4. **Azure subscription** with appropriate permissions
5. **Azure Container Registry (ACR)** created
6. **Azure Kubernetes Service (AKS)** cluster created

## Quick Setup Commands

### Option 1: Automated Setup (Recommended)

Use the provided setup script:

```bash
./build-and-deploy.sh
```

This script will:
- Create resource group: `bidr-k8s`
- Create Azure Container Registry: `BIDRcontainerregistry`
- Create AKS cluster: `BIDR-aks-cluster`
- Configure kubectl credentials
- Verify the setup

### Option 2: Manual Setup

If you prefer manual control:

```bash
# Set your variables
RESOURCE_GROUP="bidr-k8s"
LOCATION="westus"
AKS_CLUSTER="BIDR-aks-cluster"
ACR_NAME="BIDRcontainerregistry" # Must be globally unique

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure Container Registry
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic

# Create AKS cluster with ACR integration
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --attach-acr $ACR_NAME \
  --generate-ssh-keys
```

## Deployment Steps

### Step 1: Configure Your Deployment

Edit the `build-and-deploy.sh` script and update these variables:

```bash
RESOURCE_GROUP="bidr-k8s"
AKS_CLUSTER="BIDR-aks-cluster"
ACR_NAME="BIDRcontainerregistry"
```

### Step 2: Update Configuration (Optional)

Edit `k8s/configmap.yaml` to update domain names and other configuration:

```yaml
ALLOWED_HOSTS: "bidr.example.com"  # Replace with your domain
```

### Step 3: Update Secrets (Important!)

Update the secrets in `k8s/secret.yaml` with your own base64-encoded passwords:

```bash
# Generate new passwords and encode them
echo -n "your-new-postgres-password" | base64
echo -n "your-new-email-password" | base64
```

### Step 4: Run the Deployment Script

Execute the automated deployment:

```bash
./build-and-deploy.sh
```

This script will:
- Build your Docker image
- Push it to Azure Container Registry
- Deploy all Kubernetes resources
- Run makemigrations and migrate commands
- Create superuser automatically
- Wait for the deployment to be ready

### Step 5: Manual Deployment (Alternative)

If you prefer manual control, follow these steps:

```bash
# 1. Build and push Docker image
docker build -t bidr-app:latest .
az acr login --name BIDRcontainerregistry
docker tag bidr-app:latest bidrcontainerregistry.azurecr.io/bidr-app:latest
docker push bidrcontainerregistry.azurecr.io/bidr-app:latest

# 2. Get AKS credentials
az aks get-credentials --resource-group bidr-k8s --name BIDR-aks-cluster

# 3. Deploy to Kubernetes
kubectl apply -k k8s/

# 4. Check deployment status
kubectl get pods -n bidr
kubectl get services -n bidr
```

## Accessing Your Application

### Current Deployment Status (BIDR Backend)

**✅ BIDR Application Successfully Deployed!**
The BIDR Django backend application is now deployed and running on Azure Kubernetes Service.

**BIDR Infrastructure:**
- **Resource Group**: `bidr-k8s`
- **AKS Cluster**: `BIDR-aks-cluster` (West US)
- **Container Registry**: `BIDRcontainerregistry`
- **Node Pool**: 3 nodes (Standard_D4s_v3)

**Application Access Information:**
- **External IP**: `20.66.69.82`
- **Port**: `8067`
- **Main Application**: `http://20.66.69.82:8067/`
- **Admin Interface**: `http://20.66.69.82:8067/admin/`
- **API Endpoints**: `http://20.66.69.82:8067/accounts/`, `http://20.66.69.82:8067/api/`, etc.

**Superuser Credentials:**
- **Email**: `admin@bidr.com`
- **Password**: `BIDRAdmin2025!`
- **Admin URL**: `http://20.66.69.82:8067/admin/`
- **Status**: ✅ Verified and working with PostgreSQL database

**Deployment Status:**
- ✅ AKS Cluster: Running
- ✅ Container Registry: Available
- ✅ PostgreSQL Database: Running
- ✅ BIDR Application: Running (2 replicas)
- ✅ LoadBalancer Service: Active

**Deployment Summary:**
- Docker image built for linux/amd64 platform
- Image pushed to `bidrcontainerregistry.azurecr.io/bidr-app:latest`
- Kubernetes manifests applied with proper secrets and configuration
- LoadBalancer service automatically assigned external IP

## 🔄 CI/CD Pipeline (GitHub Actions)

**✅ Automated CI/CD Configured!**
The BIDR backend now includes a complete CI/CD pipeline with GitHub Actions.

### Pipeline Features

**Triggers:**
- **Pull Requests** → Run tests and code quality checks
- **Push to `develop`** → Deploy to staging environment
- **Push to `main`** → Deploy to production environment

**Pipeline Stages:**

1. **Test Stage** (All branches)
   - Python 3.11 + PostgreSQL 15 service container
   - Install dependencies and run Django tests
   - Generate coverage reports
   - Ensure code quality before deployment

2. **Production Deploy** (`main` branch)
   - Build Docker image with commit SHA tag
   - Push to Azure Container Registry
   - Deploy to AKS production namespace (`bidr`)
   - Verify rollout status and health checks

3. **Staging Deploy** (`develop` branch)
   - Build staging Docker image
   - Deploy to `bidr-staging` namespace
   - Test environment for pre-production validation

### Setup Instructions

**1. GitHub Repository Setup:**
```
Repository Settings → Secrets and variables → Actions
```

**2. Add Required Secret:**
```
Name: AZURE_CREDENTIALS
Value: (JSON from setup-cicd.sh output)
```

**3. Branch Structure:**
```bash
# Create develop branch for staging
git checkout -b develop
git push origin develop
```

### Monitoring CI/CD

**GitHub Actions:**
- View workflows in your repository's "Actions" tab
- Monitor build logs and deployment status
- Automatic rollback on failed deployments

**Kubernetes Monitoring:**
```bash
# Check deployment status
kubectl get pods -n bidr
kubectl rollout status deployment/bidr-app -n bidr

# View application logs
kubectl logs -f deployment/bidr-app -n bidr
```

### Development Workflow

```bash
# Feature development
git checkout develop
git checkout -b feature/new-feature
# ... make changes ...
git push origin feature/new-feature
# Create PR → triggers tests

# Staging deployment
git checkout develop
git merge feature/new-feature
git push origin develop  # Deploys to staging

# Production deployment
git checkout main
git merge develop
git push origin main     # Deploys to production
```

### Django Database Migrations

The deployment process automatically handles Django database migrations:

**Automated Migration Process:**
1. `python manage.py makemigrations` - Creates new migration files if models changed
2. `python manage.py migrate` - Applies migrations to the database
3. Database changes are applied during the initialization job

**Manual Migration Commands:**
```bash
# Create migrations locally
python manage.py makemigrations

# Create migrations for specific app
python manage.py makemigrations accounts

# Apply migrations manually in the cluster
kubectl exec -it deployment/bidr-app -n bidr -- python manage.py migrate

# Check migration status
kubectl exec -it deployment/bidr-app -n bidr -- python manage.py showmigrations
```

## Load Testing

The BIDR backend includes comprehensive load testing tools:

### Available Load Tests

1. **cURL Load Test** (`load_tests/curl_load_test.sh`)
   - Bash-based concurrent testing
   - Multiple endpoint testing
   - Real-time results analysis

2. **Python Load Test** (`load_tests/python_load_test.py`)
   - Python requests-based testing
   - Concurrent user simulation
   - Detailed statistics

3. **Advanced Load Test** (`load_tests/advanced_load_test.py`)
   - Stress testing scenarios
   - Spike testing
   - Endurance testing
   - CSV result export

### Running Load Tests

```bash
# Run cURL-based tests
./load_tests/curl_load_test.sh

# Run Python-based tests
python3 load_tests/python_load_test.py

# Run advanced load tests
python3 load_tests/advanced_load_test.py
```

## Infrastructure Diagram

The BIDR Kubernetes infrastructure diagram has been generated and saved as:
- `bidr_containerized_kubernetes_infrastructure.png`

To regenerate the diagram:
```bash
python3 bidr_k8s_infra_diagram.py
```

## Monitoring and Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n bidr
kubectl describe pod <pod-name> -n bidr
```

### View Logs

```bash
kubectl logs -f deployment/bidr-app -n bidr
kubectl logs -f deployment/postgres -n bidr
```

### Debug Database Connectivity

```bash
# Connect to postgres pod
kubectl exec -it deployment/postgres -n bidr -- psql -U bidruser -d bidr_db
```

### Scale Your Application

```bash
# Scale your API server
kubectl scale deployment bidr-app --replicas=3 -n bidr
```

## Resource Management

### Update Your Application

To update your application:

```bash
# Build new version
docker build -t bidr-app:v1.1 .
docker tag bidr-app:v1.1 bidrcontainerregistry.azurecr.io/bidr-app:v1.1
docker push bidrcontainerregistry.azurecr.io/bidr-app:v1.1

# Update deployment
kubectl set image deployment/bidr-app bidr-app=bidrcontainerregistry.azurecr.io/bidr-app:v1.1 -n bidr
```

### Delete Deployment

To remove everything:

```bash
kubectl delete -k k8s/
```

## Security Considerations

1. **Update default passwords** in the secret.yaml file
2. **Use Azure Key Vault** for production secrets
3. **Enable RBAC** on your AKS cluster
4. **Use private container registry** for production
5. **Configure network policies** for additional security

## Cost Optimization

For development/testing:
- Use **B-series VMs** for nodes (Standard_B2s)
- Use **Basic ACR** tier
- Scale down replicas when not in use

For production:
- Consider **spot instances** for non-critical workloads
- Use **horizontal pod autoscaling**
- Implement **cluster autoscaling**

## Support

If you encounter issues:

1. Check the BIDR backend documentation
2. Review Azure AKS documentation
3. Check pod logs and events
4. Ensure all prerequisites are met

## File Structure

```
BIDR/
├── k8s/
│   ├── namespace.yaml           # Kubernetes namespace
│   ├── secret.yaml              # Sensitive configuration
│   ├── configmap.yaml           # Application configuration
│   ├── postgres.yaml            # PostgreSQL database
│   ├── bidr-app.yaml            # Main application
│   └── kustomization.yaml       # Kustomize configuration
├── load_tests/                  # Load testing suite
├── build-and-deploy.sh          # Automated deployment script
├── documentation.md             # This documentation
└── bidr_containerized_kubernetes_infrastructure.png  # Infrastructure diagram
```
