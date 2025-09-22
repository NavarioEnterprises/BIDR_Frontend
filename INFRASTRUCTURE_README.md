# BIDR Backend Infrastructure Setup

This document provides comprehensive instructions for setting up and deploying the BIDR (Bid, Dispute, Resolve) backend infrastructure using Docker, Kubernetes, and Terraform on Microsoft Azure.

## 🏗️ Architecture Overview

The BIDR backend consists of 8 microservices:
- **Authentication Service** (Port 8001) - User management and authentication
- **Chat Service** (Port 8002) - Real-time messaging and communication
- **Payment Service** (Port 8003) - Payment processing and escrow management
- **Resolution Service** (Port 8004) - Dispute resolution and returns
- **Product Management Service** (Port 8005) - Product catalog and management
- **Notifications Service** (Port 8006) - Multi-channel notifications
- **Transactions Service** (Port 8007) - Transaction tracking and management
- **Reviews Service** (Port 8008) - Reviews and ratings system

### Infrastructure Components
- **Azure Kubernetes Service (AKS)** - Container orchestration
- **Azure Container Registry (ACR)** - Private Docker registry
- **Azure PostgreSQL Flexible Server** - Database
- **Azure Redis Cache** - Caching and sessions
- **Azure Key Vault** - Secrets management
- **Azure Storage Account** - File storage
- **Azure Application Insights** - Monitoring and analytics
- **NGINX Ingress Controller** - API Gateway and load balancing

## 🚀 Quick Start

### Prerequisites

1. **Local Development Tools**
   ```bash
   # Install Docker and Docker Compose
   # Install Azure CLI
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Install kubectl
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   
   # Install Terraform
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install terraform
   ```

2. **Azure Account Setup**
   ```bash
   # Login to Azure
   az login
   
   # Set your subscription
   az account set --subscription "Your-Subscription-ID"
   
   # Create service principal for Terraform (optional)
   az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/YOUR-SUBSCRIPTION-ID"
   ```

### Option 1: Local Development Setup

For local development and testing:

```bash
# Clone the repository
git clone <repository-url>
cd BIDR_Backend

# Run all services locally
./scripts/run-local.sh

# This will start:
# - All 8 microservices (ports 8001-8008)
# - PostgreSQL database (port 5432)
# - Redis cache (port 6379)
# - NGINX API Gateway (port 80)
# - Prometheus monitoring (port 9090)
# - Grafana dashboards (port 3000)
```

### Option 2: Azure Cloud Deployment

For production deployment on Azure:

```bash
# 1. Deploy infrastructure with Terraform
cd terraform
terraform init
terraform plan
terraform apply

# 2. Deploy applications to Kubernetes
cd ..
./scripts/deploy.sh

# 3. Create admin users
./scripts/create-superusers.sh
```

## 📋 Detailed Setup Instructions

### Local Development Setup

#### Step 1: Start Local Services
```bash
# Start all services
./scripts/run-local.sh up

# Check service status
./scripts/run-local.sh status

# View logs
./scripts/run-local.sh logs

# Stop services
./scripts/run-local.sh down
```

#### Step 2: Access Services Locally

Once services are running, you can access:

| Service | URL | Admin Panel |
|---------|-----|-------------|
| Authentication | http://localhost:8001 | http://localhost:8001/admin/ |
| Chat | http://localhost:8002 | http://localhost:8002/admin/ |
| Payment | http://localhost:8003 | http://localhost:8003/admin/ |
| Resolution | http://localhost:8004 | http://localhost:8004/admin/ |
| Products | http://localhost:8005 | http://localhost:8005/admin/ |
| Notifications | http://localhost:8006 | http://localhost:8006/admin/ |
| Transactions | http://localhost:8007 | http://localhost:8007/admin/ |
| Reviews | http://localhost:8008 | http://localhost:8008/admin/ |

**Default admin credentials**: `admin` / `admin123`

#### Step 3: API Gateway Access

All services are also accessible through the NGINX API Gateway at http://localhost:

| Endpoint | Service |
|----------|---------|
| `/api/v1/auth/` | Authentication Service |
| `/api/v1/chat/` | Chat Service |
| `/api/v1/payment/` | Payment Service |
| `/api/v1/resolution/` | Resolution Service |
| `/api/v1/products/` | Product Management |
| `/api/v1/notifications/` | Notifications |
| `/api/v1/transactions/` | Transactions |
| `/api/v1/reviews/` | Reviews |

### Azure Cloud Deployment

#### Step 1: Infrastructure Deployment

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the planned changes
terraform plan

# Deploy infrastructure
terraform apply
```

This creates:
- Resource Group: `bidr-k8s`
- AKS Cluster: `BIDR-aks-cluster`
- ACR: `bidrcontainerregistry`
- PostgreSQL server with 8 databases
- Redis cache
- Key Vault with auto-generated secrets
- Storage account
- Application Insights

#### Step 2: Application Deployment

```bash
# Deploy applications to AKS
./scripts/deploy.sh
```

This script:
1. Builds Docker images for all services
2. Pushes images to Azure Container Registry
3. Deploys services to Kubernetes
4. Sets up ingress and load balancing
5. Provides service URLs

#### Step 3: Create Admin Users

```bash
# Create superusers for all services
./scripts/create-superusers.sh
```

This generates random passwords and saves credentials to `bidr-admin-credentials.csv`.

#### Step 4: Access Cloud Services

Get the load balancer IP:
```bash
kubectl get service bidr-loadbalancer -n bidr
```

Access services at: `http://[LOAD_BALANCER_IP]/api/v1/[service]/`

## 🛠️ Configuration

### Environment Variables

Key environment variables used across services:

```bash
# Django Settings
DEBUG=False
SECRET_KEY=<auto-generated>
ALLOWED_HOSTS=*.azurecontainer.io,*.azure.com

# Database (auto-configured from Key Vault)
DATABASE_URL=postgresql://user:pass@server:5432/db_name

# Redis (auto-configured)
REDIS_URL=redis://:password@server:6379/db_number

# Email Configuration
EMAIL_HOST_USER=<from-key-vault>
EMAIL_HOST_PASSWORD=<from-key-vault>

# Payment Gateway (configure in Key Vault)
PAYSTACK_SECRET_KEY=<your-secret-key>
PAYSTACK_PUBLIC_KEY=<your-public-key>
```

### Terraform Variables

Customize deployment in `terraform/terraform.tfvars`:

```hcl
# Basic Configuration
resource_group_name = "bidr-k8s"
location = "West US"
environment = "prod"

# Container Registry
acr_name = "bidrcontainerregistry"
acr_sku = "Standard"  # Basic, Standard, Premium

# Kubernetes Configuration
aks_cluster_name = "BIDR-aks-cluster"
kubernetes_version = "1.28"
node_count = 3
node_vm_size = "Standard_D4s_v3"
enable_auto_scaling = true
min_node_count = 2
max_node_count = 10

# Database Configuration
postgresql_version = "15"
postgresql_sku = "B_Standard_B1ms"  # Basic tier
postgresql_storage_mb = 32768  # 32GB

# Redis Configuration
redis_capacity = 2  # 2GB
redis_sku = "Standard"  # Basic, Standard, Premium

# Email Configuration (optional)
email_host_user = "your-email@gmail.com"
email_host_password = "your-app-password"
```

## 🔐 Security

### Secrets Management

All secrets are managed in Azure Key Vault:

- `database-password` - PostgreSQL password
- `django-secret-key` - Django secret key
- `redis-password` - Redis authentication
- `admin-password` - Admin interface password
- `email-host-user` - SMTP username
- `email-host-password` - SMTP password

### Network Security

- Private subnets for database
- Network policies for pod communication
- HTTPS termination at load balancer
- CORS configuration for API access

### Access Control

- RBAC configured for Kubernetes
- Service accounts with minimal permissions
- Container registry authentication
- Key Vault access policies

## 📊 Monitoring

### Prometheus & Grafana

Local monitoring stack:
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/bidr_admin_password_2024)

### Azure Application Insights

Cloud monitoring:
- Performance metrics
- Error tracking  
- Dependency tracking
- Custom telemetry

### Health Checks

All services expose health check endpoints:
- `/health/` - Basic health check
- `/health/live/` - Liveness probe
- `/health/ready/` - Readiness probe

## 🚀 Scaling

### Horizontal Pod Autoscaling

Services are configured with HPA:
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Database Scaling

- PostgreSQL Flexible Server supports vertical scaling
- Read replicas can be added for read-heavy workloads
- Connection pooling via PgBouncer for high concurrency

### Cache Scaling

- Redis supports vertical scaling
- Redis Cluster for horizontal scaling (Premium tier)

## 🛠️ Troubleshooting

### Common Issues

1. **Services not starting**
   ```bash
   # Check pod status
   kubectl get pods -n bidr
   
   # Check logs
   kubectl logs -n bidr deployment/auth-service
   ```

2. **Database connection issues**
   ```bash
   # Verify database connectivity
   kubectl exec -n bidr deployment/auth-service -- python manage.py dbshell
   ```

3. **Image pull errors**
   ```bash
   # Check ACR credentials
   kubectl get secret acr-secret -n bidr -o yaml
   ```

### Debug Commands

```bash
# Local development
./scripts/run-local.sh shell auth-service  # Access service shell
./scripts/run-local.sh logs               # View all logs
./scripts/run-local.sh status             # Check status

# Kubernetes deployment
kubectl get all -n bidr                   # Check all resources
kubectl describe pod <pod-name> -n bidr   # Pod details
kubectl logs -f deployment/<service> -n bidr  # Service logs
```

## 📝 Maintenance

### Backup Strategy

1. **Database Backups**
   - Automated daily backups (Azure PostgreSQL)
   - Point-in-time recovery (35 days)
   - Cross-region backup replication

2. **Application Data**
   - Persistent volume backups
   - Azure Storage redundancy
   - Configuration backup in Git

### Updates

1. **Application Updates**
   ```bash
   # Update application code
   git pull
   ./scripts/deploy.sh  # Rebuilds and redeploys
   ```

2. **Infrastructure Updates**
   ```bash
   cd terraform
   terraform plan
   terraform apply
   ```

### Monitoring Checklist

- [ ] Service health checks passing
- [ ] Database performance metrics
- [ ] Error rates and response times
- [ ] Resource utilization
- [ ] Security alerts

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test locally
4. Submit a pull request

### Development Workflow

```bash
# Setup local environment
./scripts/run-local.sh up

# Make code changes
# ...

# Test changes
./scripts/run-local.sh restart

# Deploy to staging
./scripts/deploy.sh

# Create pull request
```

## 📞 Support

For issues and questions:

1. Check the troubleshooting section
2. Review logs and monitoring dashboards
3. Create an issue in the repository
4. Contact the development team

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## Quick Reference Commands

### Local Development
```bash
./scripts/run-local.sh up        # Start services
./scripts/run-local.sh down      # Stop services
./scripts/run-local.sh status    # Check status
./scripts/run-local.sh logs      # View logs
```

### Azure Deployment
```bash
terraform apply                  # Deploy infrastructure
./scripts/deploy.sh             # Deploy applications
./scripts/create-superusers.sh  # Create admin users
kubectl get all -n bidr         # Check deployment status
```

### Monitoring
```bash
# Local
http://localhost:3000           # Grafana
http://localhost:9090           # Prometheus

# Azure
az monitor app-insights component show --app bidr-k8s-appinsights --resource-group bidr-k8s
```

---

**Last Updated**: January 2025  
**Version**: 1.0.0
