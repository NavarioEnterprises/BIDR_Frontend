# BIDR Microservices Azure Deployment Guide

Complete deployment guide for all BIDR microservices to Azure App Service for Containers.

## 🏗️ Architecture Overview

The BIDR platform consists of 8 microservices:

1. **Authentication Service** (Port 8001) - User management & JWT tokens
2. **Product Management Service** (Port 8000) - Product requests & quotes
3. **Notifications Service** (Port 8003) - Push notifications & SMS
4. **Payment Service** (Port 8004) - Payment processing
5. **Resolution Service** (Port 8005) - Dispute resolution
6. **Reviews & Ratings Service** (Port 8006) - User feedback
7. **Transactions Service** (Port 8007) - Transaction management
8. **Chat Service** (Port 8008) - Real-time messaging

## 🚀 Quick Start - Deploy Everything

### Option 1: Complete Automated Deployment
```bash
cd azure-deployment
chmod +x 99-deploy-all-services.sh
./99-deploy-all-services.sh
```

### Option 2: Step-by-Step Deployment
```bash
# 1. Setup infrastructure
chmod +x 00-setup-infrastructure.sh
./00-setup-infrastructure.sh

# 2. Deploy services individually
chmod +x 01-deploy-authentication-service.sh
./01-deploy-authentication-service.sh

chmod +x 02-deploy-product-service.sh
./02-deploy-product-service.sh

# ... continue for all services
```

## 📋 What You Get

After deployment, each service will have:

- ✅ **Public Azure URL**: `https://bidr-[service]-service.azurewebsites.net`
- ✅ **Admin Panel**: `[URL]/admin/` (Username: `bidr_admin`, Password: `admin123`)
- ✅ **REST API**: `[URL]/api/`
- ✅ **Health Check**: `[URL]/health/`
- ✅ **Auto SSL**: HTTPS enabled automatically
- ✅ **Dedicated Database**: PostgreSQL database for each service
- ✅ **Monitoring**: Built-in Azure monitoring and logging

## 🏢 Infrastructure Created

### Azure Resources
- **Resource Group**: `bidr-production-rg`
- **Container Registry**: `bidrregistry.azurecr.io`
- **App Service Plan**: `bidr-app-service-plan` (Linux P1V3)
- **PostgreSQL Server**: `bidr-postgres-server.postgres.database.azure.com`
- **8 Web Apps**: One for each microservice

### Databases Created
- `bidr_authentication` - User accounts, profiles
- `bidr_products` - Products, requests, quotes
- `bidr_notifications` - Notification history
- `bidr_payments` - Payment records
- `bidr_resolution` - Dispute cases
- `bidr_reviews` - Reviews and ratings
- `bidr_transactions` - Transaction logs
- `bidr_chat` - Chat messages, rooms

## 💰 Cost Breakdown

| Resource | Monthly Cost | Purpose |
|----------|-------------|---------|
| App Service Plan (P1V3) | ~$80 | Hosts all 8 services |
| PostgreSQL Server | ~$70 | Database for all services |
| Container Registry | ~$5 | Docker image storage |
| **Total Estimated** | **~$155/month** | Full BIDR platform |

## 🔧 Deployment Scripts

### Infrastructure Setup
- `00-setup-infrastructure.sh` - Creates all Azure resources

### Individual Service Deployments
- `01-deploy-authentication-service.sh` - Authentication & user management
- `02-deploy-product-service.sh` - Product catalog & quotes
- `03-deploy-notifications-service.sh` - Push notifications
- `04-deploy-payment-service.sh` - Payment processing
- `05-deploy-resolution-service.sh` - Dispute resolution
- `06-deploy-reviews-service.sh` - Reviews & ratings
- `07-deploy-transactions-service.sh` - Transaction management
- `08-deploy-chat-service.sh` - Real-time chat

### Master Orchestration
- `99-deploy-all-services.sh` - Deploys everything in correct order

## 🔐 Security Features

### Built-in Security
- **HTTPS/SSL**: Automatic SSL certificates for all services
- **Environment Variables**: Secrets stored as app settings
- **Database Security**: PostgreSQL with firewall rules
- **Container Security**: Non-root user in containers
- **Admin Access**: Secure admin panels with authentication

### Admin Credentials
- **Username**: `bidr_admin`
- **Password**: `admin123`
- **Email**: `admin@bidr.com`

*Change these after deployment!*

## 📊 Service URLs After Deployment

```
Authentication Service: https://bidr-authentication-service.azurewebsites.net
Product Service: https://bidr-product-service.azurewebsites.net
Notifications Service: https://bidr-notifications-service.azurewebsites.net
Payment Service: https://bidr-payment-service.azurewebsites.net
Resolution Service: https://bidr-resolution-service.azurewebsites.net
Reviews Service: https://bidr-reviews-service.azurewebsites.net
Transactions Service: https://bidr-transactions-service.azurewebsites.net
Chat Service: https://bidr-chat-service.azurewebsites.net
```

## 🔍 Testing Your Deployment

### Health Checks
```bash
# Test all services are running
curl https://bidr-authentication-service.azurewebsites.net/health/
curl https://bidr-product-service.azurewebsites.net/health/
# ... test all services
```

### Admin Access
Visit each service's admin panel:
```
https://bidr-authentication-service.azurewebsites.net/admin/
https://bidr-product-service.azurewebsites.net/admin/
# ... all services
```

### API Testing
```bash
# Example: List users
curl https://bidr-authentication-service.azurewebsites.net/api/users/

# Example: List products
curl https://bidr-product-service.azurewebsites.net/api/v1/categories/
```

## 🛠️ Management Commands

### View Logs
```bash
# View live logs
az webapp log tail --resource-group bidr-production-rg --name bidr-authentication-service

# Download logs
az webapp log download --resource-group bidr-production-rg --name bidr-authentication-service
```

### SSH to Service
```bash
# SSH into a service
az webapp ssh --resource-group bidr-production-rg --name bidr-authentication-service

# Run Django commands
python manage.py shell
python manage.py migrate
python manage.py createsuperuser
```

### Restart Services
```bash
# Restart a specific service
az webapp restart --resource-group bidr-production-rg --name bidr-authentication-service

# Restart all services
for service in authentication product notifications payment resolution reviews transactions chat; do
    az webapp restart --resource-group bidr-production-rg --name bidr-${service}-service
done
```

## 🔄 CI/CD Integration

### GitHub Actions
After deployment, set up automated deployments:

```yaml
# .github/workflows/deploy-auth-service.yml
name: Deploy Authentication Service
on:
  push:
    branches: [main]
    paths: ['authentication_service/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: azure/docker-login@v1
        with:
          login-server: bidrregistry.azurecr.io
          username: ${{ secrets.ACR_USERNAME }}
          password: ${{ secrets.ACR_PASSWORD }}
      - run: |
          docker build -t bidrregistry.azurecr.io/bidr-authentication-service:latest ./authentication_service
          docker push bidrregistry.azurecr.io/bidr-authentication-service:latest
      - uses: azure/webapps-deploy@v2
        with:
          app-name: bidr-authentication-service
          images: bidrregistry.azurecr.io/bidr-authentication-service:latest
```

## 📈 Scaling

### Horizontal Scaling
```bash
# Scale up App Service Plan
az appservice plan update --resource-group bidr-production-rg --name bidr-app-service-plan --sku P2V3

# Scale individual services
az webapp config set --resource-group bidr-production-rg --name bidr-authentication-service --number-of-workers 3
```

### Auto-scaling
```bash
# Enable auto-scaling
az monitor autoscale create \
  --resource-group bidr-production-rg \
  --resource bidr-app-service-plan \
  --resource-type Microsoft.Web/serverfarms \
  --name autoscale-bidr \
  --min-count 1 \
  --max-count 10 \
  --count 2
```

## 🚨 Monitoring & Alerts

### Application Insights
Each service automatically gets Application Insights integration for:
- Request tracking
- Dependency monitoring  
- Exception tracking
- Performance counters

### Custom Alerts
```bash
# CPU usage alert
az monitor metrics alert create \
  --name "High CPU Usage" \
  --resource-group bidr-production-rg \
  --scopes bidr-app-service-plan \
  --condition "avg Percentage CPU > 80" \
  --description "Alert when CPU usage exceeds 80%"
```

## 🔧 Troubleshooting

### Common Issues

1. **Service won't start**
   ```bash
   # Check logs
   az webapp log tail --resource-group bidr-production-rg --name [SERVICE_NAME]
   
   # Check configuration
   az webapp config appsettings list --resource-group bidr-production-rg --name [SERVICE_NAME]
   ```

2. **Database connection issues**
   ```bash
   # Test database connectivity
   az webapp ssh --resource-group bidr-production-rg --name [SERVICE_NAME]
   python manage.py dbshell
   ```

3. **Image pull errors**
   ```bash
   # Check container registry
   az acr repository list --name bidrregistry
   
   # Verify credentials
   az acr credential show --name bidrregistry
   ```

## 🌐 Custom Domains (Optional)

### Add Custom Domain
```bash
# Add custom domain
az webapp config hostname add --resource-group bidr-production-rg --webapp-name bidr-authentication-service --hostname auth.yourdomain.com

# Add SSL certificate
az webapp config ssl upload --resource-group bidr-production-rg --name bidr-authentication-service --certificate-file cert.pfx --certificate-password [PASSWORD]
```

## 🔄 Backup & Recovery

### Database Backups
```bash
# Manual backup
az postgres server-logs download --resource-group bidr-production-rg --server-name bidr-postgres-server

# Automated backups (configured by default)
az postgres server show --resource-group bidr-production-rg --name bidr-postgres-server --query "{backupRetention:storageProfile.backupRetentionDays}"
```

### Service Configuration Backup
```bash
# Export app settings
az webapp config appsettings list --resource-group bidr-production-rg --name bidr-authentication-service > auth-service-config.json
```

## 📞 Support

For deployment issues:
1. Check the deployment logs
2. Verify Azure CLI is latest version
3. Ensure sufficient Azure credits/subscription limits
4. Review troubleshooting section above

## 🎯 Next Steps

After successful deployment:

1. **Test all services** - Use health checks and admin panels
2. **Configure inter-service communication** - Update service URLs
3. **Set up monitoring** - Configure alerts and dashboards  
4. **Security hardening** - Change default passwords, configure firewall rules
5. **Performance optimization** - Monitor and scale as needed
6. **Backup strategy** - Implement regular backups
7. **CI/CD pipeline** - Automate future deployments

---

**Congratulations!** 🎉 You now have a complete BIDR microservices platform running on Azure with professional-grade infrastructure, monitoring, and security.
