# BIDR Azure Deployment Scripts

This directory contains all the scripts needed to deploy and update your BIDR microservices platform on Azure.

## 🚀 Available Scripts

### Initial Deployment Scripts
- **`deploy-infrastructure.sh`** - Sets up Azure infrastructure (Resource Group, Container Registry)
- **`deploy-product-service.sh`** - Deploys the Product Management Service
- **`deploy-auth-service.sh`** - Deploys the Authentication Service
- **`deploy-all-services.sh`** - Master script to deploy all services at once

### Update Scripts
- **`update-product-service.sh`** - Updates the Product Management Service
- **`update-auth-service.sh`** - Updates the Authentication Service  
- **`update-all-services.sh`** - Updates all services with zero-downtime deployment

## 📋 Prerequisites

1. **Azure CLI** installed and logged in:
   ```bash
   az login
   ```

2. **Docker** installed and running

3. **jq** installed for JSON processing:
   ```bash
   # macOS
   brew install jq
   
   # Ubuntu/Debian
   sudo apt-get install jq
   ```

4. **Python 3** installed (for secret key generation)

## 🏢 Initial Deployment

### Quick Start (Deploy Everything)
```bash
# Deploy all services at once
./azure-deployment/deploy-all-services.sh
```

### Step-by-Step Deployment
```bash
# 1. Set up infrastructure
./azure-deployment/deploy-infrastructure.sh

# 2. Deploy product management service
./azure-deployment/deploy-product-service.sh

# 3. Deploy authentication service
./azure-deployment/deploy-auth-service.sh
```

## 🔄 Updating Services

### Update All Services
```bash
./azure-deployment/update-all-services.sh
```

### Update Individual Services
```bash
# Update product management service only
./azure-deployment/update-product-service.sh

# Update authentication service only
./azure-deployment/update-auth-service.sh
```

## 📊 What the Update Scripts Do

1. **Build & Tag**: Creates new Docker images with timestamp tags
2. **Backup Info**: Records current service information
3. **Zero Downtime**: Gracefully stops old containers and starts new ones
4. **Health Check**: Verifies services are running correctly
5. **Rollback Ready**: Keeps previous image versions for quick rollback

## Configuration

### Before Deployment:

1. **Update configuration variables** in the deployment scripts:
   - `RESOURCE_GROUP`: Your resource group name
   - `CONTAINER_REGISTRY`: Your container registry name (must be globally unique)
   - `LOCATION`: Azure region (e.g., "eastus", "westus2", "westeurope")

2. **Update Django settings** for production:
   - Generate a new SECRET_KEY
   - Set DEBUG=False
   - Configure ALLOWED_HOSTS
   - Set up proper database (PostgreSQL recommended)

### Post-Deployment Steps:

1. **Run database migrations**:
   ```bash
   # For ACI
   az container exec --resource-group bidr-rg --name bidr-product-service \
     --exec-command "python product_management_service/manage.py migrate"
   
   # For App Service
   az webapp ssh --resource-group bidr-prod-rg --name bidr-product-management
   python product_management_service/manage.py migrate
   
   # For AKS
   kubectl exec -it deployment/bidr-product-management -- \
     python product_management_service/manage.py migrate
   ```

2. **Create superuser**:
   ```bash
   # For ACI
   az container exec --resource-group bidr-rg --name bidr-product-service \
     --exec-command "python product_management_service/manage.py createsuperuser"
   
   # For App Service
   az webapp ssh --resource-group bidr-prod-rg --name bidr-product-management
   python product_management_service/manage.py createsuperuser
   
   # For AKS
   kubectl exec -it deployment/bidr-product-management -- \
     python product_management_service/manage.py createsuperuser
   ```

## Cost Estimation

| Service | Monthly Cost | Use Case |
|---------|-------------|----------|
| **ACI** | $20-40 | Development/Testing |
| **App Service** | $50-200 | Production |
| **AKS** | $150-500 | Enterprise/Scale |

*Costs are estimates and may vary based on usage and region.*

## Security Considerations

### Production Checklist:
- [ ] Change default SECRET_KEY
- [ ] Set DEBUG=False
- [ ] Configure proper ALLOWED_HOSTS
- [ ] Use Azure Key Vault for secrets
- [ ] Enable HTTPS/SSL
- [ ] Set up Azure Active Directory authentication
- [ ] Configure proper firewall rules
- [ ] Enable logging and monitoring
- [ ] Set up backup strategy
- [ ] Configure auto-scaling policies

### Database Recommendations:
- **Development**: SQLite (included in container)
- **Production**: Azure Database for PostgreSQL
- **Enterprise**: Azure Database for PostgreSQL with high availability

## Monitoring and Logging

All deployment options include:
- Health check endpoints (`/health/`)
- Application logging
- Container monitoring
- Azure Monitor integration

## Troubleshooting

### Common Issues:

1. **Container won't start**:
   ```bash
   # Check logs
   az container logs --resource-group RESOURCE_GROUP --name CONTAINER_NAME
   ```

2. **Static files not loading**:
   - Ensure `collectstatic` runs successfully
   - Check STATIC_URL and STATIC_ROOT settings
   - Verify Whitenoise configuration

3. **Database connection issues**:
   - Check connection string
   - Verify firewall rules
   - Ensure database exists

4. **Permission denied errors**:
   - Check file permissions in Docker image
   - Verify user permissions
   - Check Azure RBAC settings

## Support

For issues or questions:
1. Check Azure documentation
2. Review container logs
3. Use `az` CLI help commands
4. Contact Azure support

## Next Steps

After successful deployment:
1. Set up custom domain (App Service/AKS)
2. Configure SSL certificates
3. Set up CI/CD pipelines
4. Configure monitoring and alerts
5. Set up backup strategies
6. Implement scaling policies
