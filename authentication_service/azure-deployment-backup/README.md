# BIDR Authentication Service - Azure Deployment

This directory contains scripts for deploying the BIDR Authentication Service to Azure Container Instances with Application Gateway integration.

## 🚀 Quick Start

### Prerequisites
- Azure CLI installed and authenticated
- Docker (for local development)
- jq (for JSON processing)
- curl (for testing endpoints)

### One-Command Deployment
```bash
cd azure-deployment
./deploy-with-config.sh
```

## 📋 Files Overview

### Deployment Scripts
- **`deploy-auth-service.sh`** - Standalone deployment script with hardcoded configuration
- **`deploy-with-config.sh`** - Configurable deployment script (recommended)
- **`auth-service-config.env`** - Configuration file for all deployment settings

### Configuration Files
- **`auth-service-config.env`** - Main configuration file
- **`README.md`** - This documentation file

## ⚙️ Configuration

Edit `auth-service-config.env` to customize your deployment:

### Key Settings to Update
```bash
# Azure Configuration
RESOURCE_GROUP=bidr-simple-rg
CONTAINER_REGISTRY=bidrsimpleregistry
CONTAINER_NAME=bidr-auth-service

# Domain Configuration
PRODUCTION_DOMAIN=api.bidr.co.za
SERVICE_PATH=/auth/

# Security Keys (KEEP CONSISTENT with local development)
PII_ENCRYPTION_KEY=CYr9YsWhL6_TBuREQaJUQF0aHV84sdajft4UtUdPq_o=
SECRET_KEY=apML2mCNBZahA4JEP4zj0CJ7TrO/PgRYA8Z33nYKIT8=
JWT_SECRET_KEY=4DgwpcbHSk+BN8ZZvVh08vpisPNx49LtBSN/CBl0aeA=
```

### Container Configuration
```bash
CPU_CORES=1
MEMORY_GB=1.5
RESTART_POLICY=OnFailure
```

## 🔄 Deployment Process

The deployment script performs these steps:

1. **Build & Push Docker Image** - Builds the authentication service image and pushes to Azure Container Registry
2. **Clean Up** - Removes existing container if it exists
3. **Deploy Container** - Creates new Azure Container Instance
4. **Configure Gateway** - Updates Application Gateway backend pool with new container IP
5. **Health Checks** - Validates service deployment and gateway routing
6. **Testing** - Performs basic connectivity tests

## 🌐 Post-Deployment Access

After successful deployment, your service will be available at:

### Production API
- **Base URL**: `https://api.bidr.co.za/auth/`
- **Login**: `https://api.bidr.co.za/auth/login/`
- **Register**: `https://api.bidr.co.za/auth/register/`

### Direct Access (for debugging)
- **Container IP**: `http://[CONTAINER_IP]:8000/`
- **Container FQDN**: `http://[CONTAINER_FQDN]:8000/`

## 🧪 Testing Your Deployment

### Test Registration
```bash
curl -X POST 'https://api.bidr.co.za/auth/register/' \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "test@example.com",
    "password": "Test1234!",
    "confirm_password": "Test1234!",
    "first_name": "Test",
    "last_name": "User",
    "phone_number": "+27123456789",
    "role": "buyer"
  }' -k
```

### Test Login
```bash
curl -X POST 'https://api.bidr.co.za/auth/login/' \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "test@example.com",
    "password": "Test1234!"
  }' -k
```

## 🔧 Management Commands

### View Container Logs
```bash
az container logs --resource-group bidr-simple-rg --name bidr-auth-service
```

### Follow Real-time Logs
```bash
az container logs --resource-group bidr-simple-rg --name bidr-auth-service --follow
```

### Check Container Status
```bash
az container show --resource-group bidr-simple-rg --name bidr-auth-service
```

### Restart Container
```bash
az container restart --resource-group bidr-simple-rg --name bidr-auth-service
```

### Delete Container
```bash
az container delete --resource-group bidr-simple-rg --name bidr-auth-service --yes
```

## 🔒 Security Features

### Encryption
- **PII Encryption**: All personally identifiable information is encrypted using Fernet symmetric encryption
- **Consistent Keys**: Same encryption key used across local development and production
- **JWT Tokens**: Secure authentication tokens for API access

### HTTPS
- **SSL Termination**: HTTPS handled by Azure Application Gateway
- **Secure Headers**: Production-ready security configuration
- **CORS**: Configured for cross-origin requests

### Environment Security
- **Production Settings**: Debug disabled, secure headers enabled
- **Secret Management**: Sensitive data passed via environment variables
- **Container Isolation**: Service runs in isolated container environment

## 🚨 Troubleshooting

### Common Issues

#### Container Not Starting
```bash
# Check container logs
az container logs --resource-group bidr-simple-rg --name bidr-auth-service

# Check container events
az container show --resource-group bidr-simple-rg --name bidr-auth-service --query "containers[0].instanceView.events"
```

#### Application Gateway Issues
```bash
# Check backend health
az network application-gateway show-backend-health \
  --name bidr-app-gateway \
  --resource-group bidr-simple-rg
```

#### DNS/Domain Issues
```bash
# Check domain resolution
nslookup api.bidr.co.za

# Test direct container access
curl -X GET "http://[CONTAINER_IP]:8000/health/"
```

### Health Check Endpoints
- **Container Health**: `http://[CONTAINER_IP]:8000/health/`
- **Service Root**: `http://[CONTAINER_IP]:8000/`

## 📊 Monitoring

### Application Gateway Backend Health
The deployment script automatically checks the Application Gateway backend health. A "Healthy" status indicates successful routing configuration.

### Container Metrics
Monitor your container through Azure Portal:
1. Navigate to Container Instances
2. Select `bidr-auth-service`
3. View metrics like CPU, Memory, and Network usage

## 🔄 Updates and Redeployment

### For Code Changes
Simply run the deployment script again:
```bash
cd azure-deployment
./deploy-with-config.sh
```

The script will:
1. Build a new image with your latest code
2. Replace the existing container
3. Update Application Gateway routing
4. Verify the deployment

### For Configuration Changes
1. Edit `auth-service-config.env`
2. Run `./deploy-with-config.sh`

## 📝 Environment Variables Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `PII_ENCRYPTION_KEY` | Fernet key for PII encryption | Required |
| `SECRET_KEY` | Django secret key | Required |
| `JWT_SECRET_KEY` | JWT token signing key | Required |
| `DEBUG` | Django debug mode | False |
| `ALLOWED_HOSTS` | Allowed host headers | * |
| `CORS_ALLOW_ALL_ORIGINS` | CORS configuration | True |
| `DJANGO_SETTINGS_MODULE` | Django settings module | authentication_service.settings |

## 🏗️ Architecture

```
Internet
    ↓
Azure Application Gateway (HTTPS/SSL)
    ↓ (routes /auth/*)
Azure Container Instance
    ↓
Django Authentication Service
    ↓
Database (PostgreSQL/other)
```

## 🆘 Support

### Logs and Debugging
1. **Container Logs**: Use `az container logs` commands
2. **Application Gateway**: Check backend health status
3. **Domain Resolution**: Verify DNS configuration
4. **Direct Testing**: Test container IP directly

### Configuration Issues
1. **Environment Variables**: Check all required variables are set
2. **Encryption Keys**: Ensure consistency between local and production
3. **Network Configuration**: Verify Application Gateway routing rules

---

## 🎉 Success Indicators

After successful deployment, you should see:
- ✅ Container status: "Running"
- ✅ Backend health: "Healthy"
- ✅ API responses from `https://api.bidr.co.za/auth/`
- ✅ Proper error handling for invalid requests
- ✅ Encrypted PII data in database, decrypted in API responses

Your authentication service is now production-ready and accessible via the BIDR platform API gateway!
